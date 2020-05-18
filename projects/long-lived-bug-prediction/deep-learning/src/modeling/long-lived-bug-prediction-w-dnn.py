"""Predict a long lived bug."""
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
DATASETS  = ['eclipse']
FEATURES  = ['long_description']
CLASSIFIERS = ['lstm+emb']
BALANCINGS = ['smote']
RESAMPLINGS = ['repeated_cv_5x2']
METRICS = ['val_accuracy']
#THRESHOLDS    = [8, 63, 108, 365]
THRESHOLDS    = [365]
MAX_NB_TERMS  = [100, 150, 200, 250, 300]
EPOCHS        = 2
BATCH_SIZE    = 1024
MAX_NB_WORDS  = 50000

today = datetime.now()
today = today.strftime("%Y%m%d%H%M%S")

nltk.download('stopwords')
nltk.download('punkt')

kf = RepeatedStratifiedKFold(n_splits=5, n_repeats=2, random_state=42)
sm = SMOTE(sampling_strategy='auto', k_neighbors=3, random_state=42)

logging.basicConfig(filename= PROCESSED_DATA_DIR + '/{}-long-lived-bug-prediction-w-dnn.log'.format(today)
    , filemode='w', level=logging.INFO, format='%(asctime)s:: %(levelname)s - %(message)s')
#logging.basicConfig(level=logging.INFO, format='%(asctime)s:: %(levelname)s - %(message)s')
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
    data = pd.read_csv(filename, encoding='utf8', sep=',', parse_dates=True, low_memory=False)
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


def tokenize_reports(data, column, max_nb_term):
    """Clean text data of bug reports.

    Parameters
    ----------
    data: dataframe
        A bug reports dataframe.

    """
    tokenizer = Tokenizer(num_words=max_nb_term, filters='!"#$%&()*+,-./:;<=>?@[\]^_`{|}~', lower=True)
    tokenizer.fit_on_texts(data[column].values)
    X = tokenizer.texts_to_sequences(data[column].values)
    X = pad_sequences(X, maxlen=max_nb_term)
    y = pd.get_dummies(data['class']).values
    return (X, y)


def make_model(input_dim, output_dim, input_length, output_bias=None):
    """Build predicting model.

    Parameters
    ----------
    output_bias:

    input_dim:

    output_dim:

    input_length:

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

    model = keras.Sequential([
            keras.layers.Embedding(input_dim=MAX_NB_WORDS, output_dim=EMBEDDING_DIM, input_length=input_length),
            keras.layers.SpatialDropout1D(0.2),
            keras.layers.LSTM(EMBEDDING_DIM, dropout=0.2, recurrent_dropout=0.2),
            keras.layers.Dense(2, activation='softmax')
        ]
     )

    model.compile(
            optimizer=keras.optimizers.Adam(lr=1e-3),
            loss=keras.losses.BinaryCrossentropy(),
            metrics=METRICS
    )

    return model

results = None
parameters = itertools.product(DATASETS, FEATURES, CLASSIFIERS, 
    BALANCINGS, RESAMPLINGS, METRICS, 
    THRESHOLDS, MAX_NB_TERMS) 

for parameter in parameters:
    dataset = parameter[0]
    feature = parameter[1]
    classifier = parameter[2]
    balancing =  parameter[3]
    resampling =  parameter[4]
    metric = parameter[5]
    threshold = parameter[6]
    max_nb_term = parameter[7]
   
    logging.info('>> Starting prediction')
    logging.info('Dataset       : {}'.format(dataset))
    logging.info('Feature       : {}'.format(feature))
    logging.info('Classifier    : {}'.format(classifier))
    logging.info('Balancing     : {}'.format(balancing))
    logging.info('Resampling    : {}'.format(resampling))
    logging.info('Metric        : {}'.format(metric))
    logging.info('Threshold     : {}'.format(threshold))
    logging.info('Terms         : {}'.format(max_nb_term))
    
    TRAIN_FILE = RAW_DATA_DIR + '/20190917_{}_bug_report_{}_train_data.csv'.format(dataset, threshold)
    train_data = read_reports(TRAIN_FILE, feature)
    TEST_FILE  = RAW_DATA_DIR + '/20190917_{}_bug_report_{}_test_data.csv'.format(dataset, threshold)
    test_data  = read_reports(TEST_FILE, feature)

    logging.info('Bug reports train file read: {}'.format(TRAIN_FILE))
    logging.info('Bug reports test file read: {}'.format(TEST_FILE))
    neg, pos = np.bincount(train_data['class'])
    total = neg + pos
    logging.info('Reports in train - Total: {} Positive: {} ({:.2f}% of total)'.format(total, pos, 100 * pos / total))
    logging.info('Reports in train - Total: {} Negative: {} ({:.2f}% of total)'.format(total, neg, 100 * neg / total))
    neg, pos = np.bincount(test_data['class'])
    total = neg + pos
    logging.info('Reports in test - Total: {} Positive: {} ({:.2f}% of total)'.format(total, pos, 100 * pos / total))
    train_data = clean_reports(train_data, feature)
    test_data  = clean_reports(test_data, feature)
    logging.info('Bug reports {} cleaned.'.format(feature))

    early_stopping = tf.keras.callbacks.EarlyStopping(
        monitor=metric,
        verbose=1,
        patience=10,
        mode='max',
        restore_best_weights=True
    )

    logging.info('Balancing data started')
    X_main, y_main = tokenize_reports(train_data, feature, max_nb_term)
    logging.info('BEFORE SMOTE:')
    logging.info('Reports shape    : data {} label {}'.format(X_main.shape, y_main.shape))
    logging.info('Reports class distribution : 0 ({}) 1 ({})'.format(
            np.sum(y_main.argmax(axis=1) == 0), 
            np.sum(y_main.argmax(axis=1) == 1)
        )
    )     
    
    X_main, y_main = sm.fit_resample(X_main, y_main.argmax(axis=1))
    y_main = pd.get_dummies(y_main).values
    logging.info('AFTER SMOTE:')
    logging.info('Reports shape    : data {} label {}'.format(X_main.shape, y_main.shape))
    logging.info('Reports class distribution : 0 ({}) 1 ({})'.format(
            np.sum(y_main.argmax(axis=1) == 0), 
            np.sum(y_main.argmax(axis=1) == 1)
        )
    )
    
    X_test, y_test = tokenize_reports(test_data, feature, max_nb_term)
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
    for train_index, val_index in kf.split(X_main, y_main.argmax(axis=1)):
        fold += 1
        X_train = X_main[train_index]
        y_train = y_main[train_index]
        X_val   = X_main[val_index]
        y_val   = y_main[val_index]

       #np.savetxt(PROCESSED_DATA_DIR+'/20190917_eclipse_train_fold_{}_{}_{}.csv'.format(
       #     threshold, max_nb_term, fold), np.concatenate((X_train, y_train), axis=1), delimiter=',')
       #np.savetxt(PROCESSED_DATA_DIR+'/20190917_eclipse_val_fold_{}_{}_{}.csv'.format(
       #     threshold, max_nb_term, fold), np.concatenate((X_val, y_val), axis=1), delimiter=',')
        
        logging.info('Builing model for Fold# {} started'.format(fold))
        model   = make_model(input_dim=X_train.shape[1]
            , output_dim=X_train.shape[1]
            , input_length=X_train.shape[1])

        #model.layers[-1].bias.assign([0.0, 0.0])
       
        model.fit(X_train, y_train, validation_data=(X_val, y_val),
            verbose=1, epochs=EPOCHS, batch_size=BATCH_SIZE,    
            callbacks=[early_stopping]
        )
        logging.info('Builing model for Fold# {} finished'.format(fold))

        fold_prediction = model.predict_classes(X_val,batch_size=BATCH_SIZE)
        fold_balanced_accuracy = metrics.balanced_accuracy_score(y_val.argmax(axis=1), fold_prediction)
        logging.info(f"Fold {fold} score (balanced accuracy): {fold_balanced_accuracy}")
        if (fold_balanced_accuracy > best_balanced_accuracy):
            best_balanced_accuracy = fold_balanced_accuracy
            best_model    = model

        
    logging.info(f"Best fold score (accuracy): {best_balanced_accuracy}")
    test_predictions_baseline  = best_model.predict_classes(X_test, batch_size=BATCH_SIZE)
    balanced_accuracy = metrics.balanced_accuracy_score(y_test.argmax(axis=1), test_predictions_baseline)
    baseline_results = best_model.evaluate(X_test, y_test, batch_size=BATCH_SIZE, verbose=0)
    
    #cm = confusion_matrix(y_test.argmax(axis=1), test_predictions_baseline > 0.5)
    #balanced_accuracy=((cm[1][1]/(cm[1][1]+cm[1][0])) + (cm[0][0]/(cm[0][0]+cm[0][1])))/2
    
    for name, value in zip(best_model.metrics_names, baseline_results):
        logging.info('{}:{}'.format(name, value))
    
    logging.info('balanced accuracy : {}'.format(balanced_accuracy))
    logging.info('Model evaluated.')

    if results is None:
        columns  = ['project', 'feature', 'classifier']
        columns += ['balancing', 'resampling', 'metric', 'threshold', 'terms']
        columns += ['train_size', 'train_size_class_0', 'train_size_class_1']
        columns += ['val_size', 'val_size_class_0', 'val_size_class_1']
        columns += ['test_size', 'test_size_class_0', 'test_size_class_1']
        columns += model.metrics_names
        columns += ['sensitivity', 'specificity', 'balanced_acc']
        columns += ['fmeasure', 'epochs']
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

    result = {
        'project'    : dataset,
        'feature'    : feature,
        'classifier' : classifier,
        'balancing'  : balancing,
        'resampling' : resampling,
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
        'auc': baseline_results[8], 
        'sensitivity': sensitivity,
        'specificity': specificity,
        'balanced_acc': balanced_accuracy,
        'fmeasure': fmeasure,
        'epochs': EPOCHS
    }
    results = results.append(result, ignore_index=True)

logging.info('Metricas recorded')
results.to_csv(PROCESSED_DATA_DIR+'/{}-long-lived-bug-prediction-w-dnn-results.csv'.format(today), index_label='#')
logging.info('>> Pridicting finished')
