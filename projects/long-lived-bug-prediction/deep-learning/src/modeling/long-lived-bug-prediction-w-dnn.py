"""Predict a long lived bug."""
SEED_NUMBER = 42
from numpy.random import seed
seed(SEED_NUMBER)
from tensorflow.random import set_seed
set_seed(SEED_NUMBER+1)

import os
import re
import logging
import nltk
import itertools

from datetime import datetime

from nltk.corpus import stopwords
import numpy as np
import pandas as pd

from sklearn import metrics
from sklearn.model_selection import train_test_split
from sklearn.model_selection import RepeatedStratifiedKFold

from sklearn.metrics import confusion_matrix
from sklearn.feature_extraction.text import TfidfVectorizer

import tensorflow as tf
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
from tensorflow import keras

from imblearn.over_sampling import SMOTE

from collections import Counter

# environment
path = os.getcwd()
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

ROOT_DIR = os.path.expanduser('~') + '/Workspace/doctorate/projects/long-lived-bug-prediction/deep-learning'    
RAW_DATA_DIR = ROOT_DIR + '/data/raw'
PROCESSED_DATA_DIR = ROOT_DIR + '/data/processed'

# constants
# DATASETS  = ["freedesktop", "gcc", "eclipse", "gnome", "mozilla", "winehq"]
DATASETS  = ["gcc"]
FEATURES  = ['long_description']
CLASSIFIERS = ['lstm+emb']
BALANCINGS = ['smote']
#BALANCINGS = ['unbalanced']
RESAMPLINGS = ['repeated_cv_5x2']
METRICS = ['val_accuracy']
VECTORIZES    = ['tfidf']
THRESHOLDS    = {
    'eclipse': [8, 63, 108, 365],   
    'freedesktop': [28, 173, 162, 365],   
    'gcc': [63, 337, 475, 365],
    'gnome': [23, 202, 162, 365],
    'mozilla': [24, 278, 188, 365],
    'winehq': [220, 491, 798, 365]
}
MAX_NB_TERMS  = [100, 150, 200, 250, 300]
EPOCHS        = 200
BATCH_SIZE    = 1024
MAX_NB_WORDS  = 50000
DEBUG = True
EXPERIMENT  = 'E1' 

if (DEBUG):
    THRESHOLDS    = {
        'freedesktop': [28],   
        'gcc': [63],
        'gnome': [23],
        'mozilla': [24],
        'winehq': [220]
    }
    MAX_NB_TERMS  = [100]
    EPOCHS        = 1
    EXPERIMENT    = 'XX'

today = datetime.now()
today = today.strftime("%Y%m%d%H%M%S")

nltk.download('stopwords')
nltk.download('punkt')

"""
Creates a stratified repeated k-fold cross validator object. Number of folds equals to 5 
and number of times equalts to 2 times.
"""
kf = RepeatedStratifiedKFold(n_splits=5, n_repeats=2, random_state=SEED_NUMBER)

"""
Creates a stratified smote oversampler object using 'auto' strategy and neighbors 
equals to 3. The auto strategy resample all classes but the majority class.
"""
sm = SMOTE(sampling_strategy='auto', k_neighbors=3, random_state=SEED_NUMBER)

if (DEBUG):
    logging.basicConfig(level=logging.INFO, format='%(asctime)s:: %(levelname)s - %(message)s')
else:
    logging.basicConfig(filename= PROCESSED_DATA_DIR + '/{}-long-lived-bug-prediction-w-dnn.log'.format(today)
   , filemode='w', level=logging.INFO, format='%(asctime)s:: %(levelname)s - %(message)s')

logging.info('Setup completed')


def clean_text(text):
    """Clean a text.

    Parameters
    ----------
    text: string
        A text string.

    Returns
    -------
    text:string
        A modified initial text string
    """
    if text != text:
        return ' '

    replace_by_space = re.compile("[/(){}\[\]\|@,;]")
    replace_bad_symbols = re.compile('[^0-9a-z #+_]')
    english_stopwords = set(stopwords.words('english'))
    text = text.lower()
    text = replace_by_space.sub(' ', text)
    text = replace_bad_symbols.sub('', text)
    text = ' '.join(word for word in text.split() if word not in english_stopwords)
    return text


def read_reports(filename, feature):
    """Read a bug reports file.

    Parameters
    ----------
    filename: string
        A datafile name.

    """
    data = pd.read_csv(filename, encoding='utf8', sep=',', 
        parse_dates=True, low_memory=False)
    data = data[[feature, 'class']]
    data = data.dropna()
    return data

def print_report(data, index):
    """Print a bug report.

    Parameters
    ----------
    data: dataframe
        A bug reports dataframe.
    index: int
        A index of a bug report in dataframe.

    """
    sample = data.loc[(data.index == index)].values[0]
    if len(sample) > 0:
        print(sample[0])
        print('class', sample[1])


def clean_reports(data, column):
    """Clean text data of bug reports.

    Parameters
    ----------
    data: dataframe
        A bug reports dataframe.

    """
    cleaned_data = data.copy()
    cleaned_data = cleaned_data.reset_index(drop=True)
    cleaned_data[column] = cleaned_data[column].apply(clean_text)
    cleaned_data[column] = cleaned_data[column].str.replace('\d+', '')

    return cleaned_data


def tokenize_reports(data, column, max_nb_term, vectorize='sequence'):
    """Clean text data of bug reports.

    Parameters
    ----------
    data: dataframe
        A bug reports dataframe.

    """
    tokenizer = Tokenizer(num_words=MAX_NB_WORDS+1
            , filters='!"#$%&()*+,-./:;<=>?@[\]^_`{|}~', lower=True)
    tokenizer.fit_on_texts(data[column].values)
    
    if (vectorize == 'tfidf'):
        X = tokenizer.texts_to_matrix(data[column].values, mode="tfidf")
        X = X[:, 1:max_nb_term+1]
    else:
        X = tokenizer.texts_to_sequences(data[column].values)
        X = pad_sequences(X, maxlen=max_nb_term)

    y = pd.get_dummies(data['class']).values
    
    return (X, y)


def make_model(input_dim, output_dim, input_length, vectorize, output_bias=None):
    """Build predicting model.
    """
    EMBEDDING_DIM = 100    

    METRICS = [
        keras.metrics.TruePositives(name='tp'),
        keras.metrics.FalsePositives(name='fp'),
        keras.metrics.TrueNegatives(name='tn'),
        keras.metrics.FalseNegatives(name='fn'),
        keras.metrics.BinaryAccuracy(name='accuracy'),
        keras.metrics.Precision(name='precision'),
        keras.metrics.Recall(name='recall'),
        keras.metrics.AUC(name='auc')
    ]

    if output_bias is not None:
        output_bias = tf.keras.initializers.Constant(output_bias)

    if vectorize == "tfidf":
        model = keras.Sequential([
                #keras.layers.Embedding(input_dim=MAX_NB_WORDS, output_dim=EMBEDDING_DIM, input_length=input_length),
                #keras.layers.SpatialDropout1D(0.2),
                keras.layers.LSTM(units=EMBEDDING_DIM, input_shape=input_length, dropout=0.2, recurrent_dropout=0.2),
                keras.layers.Dense(2, activation='sigmoid')
            ]
        )
    else:
        model = keras.Sequential([
                keras.layers.Embedding(input_dim=MAX_NB_WORDS, output_dim=EMBEDDING_DIM, input_length=input_length),
                keras.layers.SpatialDropout1D(0.2),
                keras.layers.LSTM(EMBEDDING_DIM, dropout=0.2, recurrent_dropout=0.2),
                keras.layers.Dense(2, activation='sigmoid')
            ]
        )

    model.compile(
            optimizer=keras.optimizers.Adam(lr=1e-3),
            loss=keras.losses.BinaryCrossentropy(),
            metrics=METRICS
    )

    return model

results = None

"""
Makes a cartesian products with experiments parameters to yield
a full combination of them.
"""
parameters = itertools.product(
    DATASETS, 
    FEATURES, 
    CLASSIFIERS, 
    BALANCINGS, 
    RESAMPLINGS, 
    METRICS, 
    MAX_NB_TERMS,
    VECTORIZES
) 

for parameter in parameters:
    dataset = parameter[0]
    feature = parameter[1]
    classifier = parameter[2]
    balancing =  parameter[3]
    resampling =  parameter[4]
    metric = parameter[5]
    max_nb_term = parameter[6]
    vectorize = parameter[7]

    for threshold in THRESHOLDS[dataset]:
        logging.info('>> Starting prediction')
        logging.info('Dataset       : {}'.format(dataset))
        logging.info('Feature       : {}'.format(feature))
        logging.info('Classifier    : {}'.format(classifier))
        logging.info('Balancing     : {}'.format(balancing))
        logging.info('Resampling    : {}'.format(resampling))
        logging.info('Metric        : {}'.format(metric))
        logging.info('Threshold     : {}'.format(threshold))
        logging.info('Terms         : {}'.format(max_nb_term))
        logging.info('Vectorize     : {}'.format(vectorize))

        TRAIN_FILE = RAW_DATA_DIR + '/20190917_{}_bug_report_{}_train_data.csv'.format(dataset, threshold)
        train_data = read_reports(TRAIN_FILE, feature)
        TEST_FILE  = RAW_DATA_DIR + '/20190917_{}_bug_report_{}_test_data.csv'.format(dataset, threshold)
        test_data  = read_reports(TEST_FILE, feature)

        logging.info('Bug reports train file  : {}'.format(TRAIN_FILE))
        logging.info('Bug reports test file   : {}'.format(TEST_FILE))
        neg, pos = np.bincount(train_data['class'])
        total = neg + pos
        logging.info('Reports in train - Total: {} Positive: {} ({:.2f}% of total)'.format(total, pos, 100 * pos / total))
        logging.info('Reports in train - Total: {} Negative: {} ({:.2f}% of total)'.format(total, neg, 100 * neg / total))
        neg, pos = np.bincount(test_data['class'])
        total = neg + pos
        logging.info('Reports in test - Total : {} Positive: {} ({:.2f}% of total)'.format(total, pos, 100 * pos / total))
        train_data = clean_reports(train_data, feature)
        test_data  = clean_reports(test_data, feature)
        logging.info('Bug reports {} cleaned.'.format(feature))

        """
        Stop training when a monitored metric has stopped improving.
        """
        early_stopping = tf.keras.callbacks.EarlyStopping(
            monitor=metric,     # quantify to be monitored
            patience=10,        # number of epochs with no improvement after training will be stopped
            mode='max',         # it will stop when the quantity monitored has stopped increasing
            restore_best_weights=True, # restore model weigths from the epoch with the best value of monitored quantity
            verbose=1           # verbosity mode
        )
        
        logging.info('Balancing data started with {} method'.format(balancing))
        X_main, y_main = tokenize_reports(train_data, feature, max_nb_term, vectorize)
        logging.info('BEFORE:')
        logging.info('Reports shape    : data {} label {}'.format(X_main.shape, y_main.shape))
        logging.info('Reports class distribution : 0 ({}) 1 ({})'.format(
                np.sum(y_main.argmax(axis=1) == 0), 
                np.sum(y_main.argmax(axis=1) == 1)
            )
        )     
        
        if (balancing == "smote"):
            X_main, y_main = sm.fit_resample(X_main, y_main.argmax(axis=1))
            y_main = pd.get_dummies(y_main).values
            logging.info('AFTER Balancing:')
            logging.info('Redports shape    : data {} label {}'.format(X_main.shape, y_main.shape))
            logging.info('Reports class distribution : 0 ({}) 1 ({})'.format(
                    np.sum(y_main.argmax(axis=1) == 0), 
                    np.sum(y_main.argmax(axis=1) == 1)
                )
            )
        else:
            logging.info('Balancing is not required.')

        
        X_test, y_test = tokenize_reports(test_data, feature, max_nb_term, vectorize)
        logging.info('Shape of test data tensor : {}'.format(X_test.shape))
        logging.info('Shape of test label tensor: {}'.format(y_test.shape))
        logging.info('Class distribution in test label tensor: {}(0) {}(1)'.format(
            np.sum(y_test.argmax(axis=1) == 0), 
            np.sum(y_test.argmax(axis=1) == 1)
            )
        )
        logging.info('Balancing data finished')

        logging.info('Trainning with k-folding started')
        fold     = 0
        best_balanced_accuracy = 0
        
        """
        Generate indices to split data into training and test set.
        """
        folds = kf.split(
            X_main,                 # training data
            y_main.argmax(axis=1)   # the target variable
        )
        for train_index, val_index in folds:
            fold += 1
            X_train = X_main[train_index]
            y_train = y_main[train_index]
            X_val   = X_main[val_index]
            y_val   = y_main[val_index]

            # logging.info('Salving File for Fold# {} started'.format(fold))
            # FOLD_TRAIN_FILE = PROCESSED_DATA_DIR+'/20190917_eclipse_train_fold_{}_{}_{}.csv'.format(
            #    threshold, max_nb_term, fold)
            # FOLD_VAL_FILE   = PROCESSED_DATA_DIR+'/20190917_eclipse_val_fold_{}_{}_{}.csv'.format(
            #    threshold, max_nb_term, fold)
            
            # record folds to experiments with other dnn architectures.
            # if (not (os.path.exists(FOLD_TRAIN_FILE))):
            #    np.savetxt(FOLD_TRAIN_FILE, np.concatenate((X_train, y_train), axis=1), delimiter=',')
        
            # if (not (os.path.exists(FOLD_VAL_FILE))): 
            #    np.savetxt(FOLD_VAL_FILE, np.concatenate((X_val, y_val), axis=1), delimiter=',')

            # logging.info('Salving File for Fold# {} finished'.format(fold))
            logging.info('Building model for Fold# {} started'.format(fold))
            if (vectorize == 'tfidf'):
                X_train = X_train[:, :, None] 
                X_val = X_val[:, :, None]

            fold_model   = make_model(input_dim=X_train.shape[1]
                , output_dim=X_train.shape[1]
                , input_length=X_train.shape[1:]
                , vectorize=vectorize)

            
            fold_model.fit(X_train, y_train, validation_data=(X_val, y_val),
                verbose=1, epochs=EPOCHS, batch_size=BATCH_SIZE,    
                callbacks=[early_stopping]
            )
            logging.info('Builing model for Fold# {} finished'.format(fold))

            logging.info('Evaluating model for Fold# {} finished'.format(fold))
            fold_prediction = (fold_model.predict(X_val) > 0.5).astype("int32")
            fold_prediction = fold_prediction.argmax(axis=1)
            #print(fold_prediction)
            #exit()
            #fold_prediction = fold_model.predict_classes(X_val,batch_size=BATCH_SIZE)
            fold_balanced_accuracy = metrics.balanced_accuracy_score(y_val.argmax(axis=1), fold_prediction)
            logging.info(f"Fold {fold} score (balanced accuracy): {fold_balanced_accuracy}")
            if (fold_balanced_accuracy > best_balanced_accuracy):
                best_balanced_accuracy = fold_balanced_accuracy
                best_model    = fold_model
            logging.info('Evaluating model for Fold# {} finished'.format(fold))

        logging.info('Evaluating final model started')
        logging.info(f"Best fold score (accuracy): {best_balanced_accuracy}")
        if (vectorize == 'tfidf'):
            X_test = X_test[:, :, None] 
       
        test_predictions_baseline  = (best_model.predict(X_test) > 0.5).astype("int32")
        test_predictions_baseline  = test_predictions_baseline.argmax(axis=1)

        balanced_accuracy = metrics.balanced_accuracy_score(y_test.argmax(axis=1), test_predictions_baseline)
        baseline_results = best_model.evaluate(X_test, y_test, batch_size=BATCH_SIZE, verbose=1)
        for name, value in zip(best_model.metrics_names, baseline_results):
            logging.info('{}:{}'.format(name, value))
        
        logging.info('Balanced accuracy : {}'.format(balanced_accuracy))
        logging.info('Evaluating final model finished')
        
        logging.info('Extracting evaluating metrics started')
        if results is None:
            columns  = ['project', 'feature', 'classifier']
            columns += ['balancing', 'resampling', 'vectorizing', 'metric', 'threshold', 'terms']
            columns += ['train_size', 'train_size_class_0', 'train_size_class_1']
            columns += ['val_size', 'val_size_class_0', 'val_size_class_1']
            columns += ['test_size', 'test_size_class_0', 'test_size_class_1']
            columns += best_model.metrics_names
            columns += ['sensitivity', 'specificity', 'balanced_acc']
            columns += ['fmeasure', 'epochs', 'experiment']
            results = pd.DataFrame(columns=columns)

        loss = baseline_results[0] 
        tp = baseline_results[1]
        fp = baseline_results[2]
        tn = baseline_results[3]
        fn = baseline_results[4]
        accuracy = baseline_results[5]
        sensitivity = tp / (tp + fn) 
        specificity = tn / (tn + fp)
        precision   = baseline_results[6]
        recall      = baseline_results[7]
        fmeasure = (2 * precision * recall) / (precision + recall)
        auc = baseline_results[8]

        if (DEBUG):
            logging.info('DEBUG: loss : {}'.format(loss))
            logging.info('DEBUG: tp : {}'.format(tp))
            logging.info('DEBUG: fp : {}'.format(fp))
            logging.info('DEBUG: tn : {}'.format(tn))
            logging.info('DEBUG: fn : {}'.format(fn))
            logging.info('DEBUG: accuracy : {}'.format(accuracy))
            logging.info('DEBUG: sensitivity : {}'.format(sensitivity))
            logging.info('DEBUG: specificity : {}'.format(specificity))
            logging.info('DEBUG: precision : {}'.format(precision))
            logging.info('DEBUG: recall : {}'.format(recall))
            logging.info('DEBUG: fmeasure : {}'.format(fmeasure))
            logging.info('DEBUG: auc : {}'.format(auc))

        result = {
            'project'    : dataset,
            'feature'    : feature,
            'classifier' : classifier,
            'balancing'  : balancing,
            'resampling' : resampling,
            'vectorizing': vectorize,
            'metric'     : metric,
            'threshold'  : threshold,
            'terms' : max_nb_term,
            'train_size' : y_train.shape[0],
            'train_size_class_0': np.sum(y_train.argmax(axis=1) == 0),
            'train_size_class_1': np.sum(y_train.argmax(axis=1) == 1),
            'val_size': y_val.shape[0],
            'val_size_class_0': np.sum(y_val.argmax(axis=1) == 0),
            'val_size_class_1': np.sum(y_val.argmax(axis=1) == 1),
            'test_size': y_test.shape[0],
            'test_size_class_0': np.sum(y_test.argmax(axis=1) == 0),
            'test_size_class_1': np.sum(y_test.argmax(axis=1) == 1),
            'loss': loss,
            'tp': tp,
            'fp': fp,
            'tn': tn,
            'fn': fn,
            'accuracy': accuracy,
            'precision': precision,
            'recall': recall,
            'auc': auc, 
            'sensitivity': sensitivity,
            'specificity': specificity,
            'balanced_acc': balanced_accuracy,
            'fmeasure': fmeasure,
            'epochs': EPOCHS,
            'experiment' : EXPERIMENT
        }
        results = results.append(result, ignore_index=True)
        logging.info('Extracting evaluating metrics finished')
    
logging.info('Metrics recorded')
results.to_csv(PROCESSED_DATA_DIR+'/{}-long-lived-bug-prediction-w-dnn-results.csv'.format(today), index_label='#')
logging.info('>> Pridicting finished')