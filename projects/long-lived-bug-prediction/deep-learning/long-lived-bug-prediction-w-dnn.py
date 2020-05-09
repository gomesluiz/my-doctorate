"""Predict a long lived bug."""
import os
import re
import logging
import matplotlib as mpl
import matplotlib.pyplot as plt
import nltk

from datetime import datetime

from nltk.corpus import stopwords
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.metrics import confusion_matrix
from sklearn.feature_extraction.text import TfidfVectorizer

import tensorflow as tf
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
from tensorflow import keras

from imblearn.over_sampling import SMOTE

from collections import Counter

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
mpl.rcParams['figure.figsize'] = (12, 10)
nltk.download('stopwords')
nltk.download('punkt')
COLORS = plt.rcParams['axes.prop_cycle'].by_key()['color']
cwd = os.getcwd()
today = datetime.now()
today = today.strftime("%Y%m%d%H%M%S")
sm = SMOTE(sampling_strategy='minority', random_state=42)

logging.basicConfig(filename=cwd + '/results/{}-long-lived-bug-prediction-w-dnn.log'.format(today), filemode='w', level=logging.INFO, format='%(asctime)s:: %(levelname)s - %(message)s')
#logging.basicConfig(level=logging.INFO, format='%(asctime)s:: %(levelname)s - %(message)s')
logging.info('Setup completed')

# constants
DATAFILE = cwd + '/datasets/20190917_eclipse_bug_report_data.csv'
TRAIN = cwd + '/datasets/20190917_eclipse_bug_report_train_data.csv'
TEST  = cwd + '/datasets/20190917_eclipse_bug_report_test_data.csv'

#FEATURES  = ['long_description', 'short_description']
FEATURES  = ['long_description']
MAX_NB_TERMS = [100, 150, 200, 250, 300]
THRESHOLDS   = [8, 63, 108, 365]
EPOCHS        = 200
BATCH_SIZE    = 1024
MAX_NB_WORDS  = 50000
#METRICS = ['val_accuracy', 'val_auc']
METRICS = ['val_accuracy']
BALANCING = 'unbalanced'

def tokenizer(text):
    words = nltk.word_tokenize(text)
    return words

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
    #data['class'] = data['bug_fix_time'].apply(lambda t: 1 if t > threshold else 0)
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
    #y = pd.get_dummies(data['class']).values
    y = data['class']

    return (X, y)


def make_model(input_dim, output_dim, input_length, output_bias=None):
    """Build predicting model.

    Parameters
    ----------
    output_bias:
        A bug reports dataframe.
    input_dim:
        A bug reports dataframe.
    output_dim:
        A bug reports dataframe.
    input_length:
        A bug reports dataframe.
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
            keras.layers.Dense(2, activation='sigmoid')
        ]
     )

    model.compile(
            optimizer=keras.optimizers.Adam(lr=1e-3),
            loss=keras.losses.BinaryCrossentropy(),
            metrics=METRICS
    )

    return model


tf.autograph.experimental.do_not_convert(
    func=None
)
results = None

for feature in FEATURES:
    logging.info('Starting prediction using feature {}'.format(feature))
    for threshold in THRESHOLDS:
        logging.info('Threshold: {}'.format(threshold))
       
        TRAIN_FILE = cwd + '/datasets/20190917_eclipse_bug_report_{}_train_data.csv'.format(threshold)
        train_data = read_reports(TRAIN_FILE, feature)
        TEST_FILE  = cwd + '/datasets/20190917_eclipse_bug_report_{}_test_data.csv'.format(threshold)
        test_data  = read_reports(TEST_FILE, feature)

        logging.info('Bug reports train file read: {}'.format(TRAIN_FILE))
        logging.info('Bug reports test file read: {}'.format(TEST_FILE))
        neg, pos = np.bincount(train_data['class'])
        total = neg + pos
        logging.info('Reports in train - Total: {} Positive: {} ({:.2f}% of total)'.format(total, pos, 100 * pos / total))
        neg, pos = np.bincount(test_data['class'])
        total = neg + pos
        logging.info('Reports in test - Total: {} Positive: {} ({:.2f}% of total)'.format(total, pos, 100 * pos / total))
        train_data = clean_reports(train_data, feature)
        test_data  = clean_reports(test_data, feature)
        logging.info('Bug reports {} cleaned.'.format(feature))

        for max_nb_term in MAX_NB_TERMS:
            for metric in METRICS:
                logging.info('Metric: {}'.format(metric))
                early_stopping = tf.keras.callbacks.EarlyStopping(
                    monitor=metric,
                    verbose=1,
                    patience=10,
                    mode='max',
                    restore_best_weights=True
                )

                X_train, y_train = tokenize_reports(train_data, feature, max_nb_term)
                logging.info('Data tokenized using {} terms'.format(max_nb_term))
                logging.info('Shape of train data tensor : {}'.format(X_train.shape))
                logging.info('Shape of train label tensor: {}'.format(y_train.shape))

                X_test, y_test = tokenize_reports(test_data, feature, max_nb_term)
                logging.info('Shape of test data tensor : {}'.format(X_test.shape))
                logging.info('Shape of test label tensor: {}'.format(y_test.shape))

                X_train, X_val, y_train, y_val = train_test_split(X_train, y_train, test_size=0.1, random_state=42)    
                logging.info('Spliting data started')
            
                X_train, y_train = sm.fit_resample(X_train, y_train)
                
                y_train = pd.get_dummies(y_train).values
                y_val   = pd.get_dummies(y_val).values
                y_test  = pd.get_dummies(y_test).values
                logging.info('Training shape    : X={} y={}'.format(X_train.shape, y_train.shape))
                logging.info('Training shape    : Class 0={} Class 1={}'.format(
                        np.sum(y_train.argmax(axis=1) == 0), 
                        np.sum(y_train.argmax(axis=1) == 1)
                    )
                )              
                logging.info('Validation shape  : X={} y={}'.format(X_val.shape, y_val.shape))
                logging.info('Validation shape  : Class 0={} Class 1={}'.format(
                        np.sum(y_val.argmax(axis=1) == 0), 
                        np.sum(y_val.argmax(axis=1) == 1)
                    )
                )
                logging.info('Test shape    : X={} y={}'.format(X_test.shape, y_test.shape))
                logging.info('Test shape    : Class 0={} Class 1={}'.format(
                        np.sum(y_test.argmax(axis=1) == 0), 
                        np.sum(y_test.argmax(axis=1) == 1)
                    )
                )
                logging.info('Spliting data concluded')
                
                model   = make_model(input_dim=X_train.shape[1], output_dim=X_train.shape[1], input_length=X_train.shape[1])
                model.layers[-1].bias.assign([0.0, 0.0])
                history = model.fit(
                    X_train,
                    y_train,
                    batch_size=BATCH_SIZE,
                    epochs=EPOCHS,
                    validation_data=(X_val, y_val),
                    callbacks=[early_stopping],
                    verbose=1
                )
                logging.info('Model built.')
                train_predictions_baseline = model.predict_classes(X_train, batch_size=BATCH_SIZE)
                test_predictions_baseline  = model.predict_classes(X_test, batch_size=BATCH_SIZE)
                baseline_results = model.evaluate(X_test, y_test, batch_size=BATCH_SIZE, verbose=0)
                for name, value in zip(model.metrics_names, baseline_results):
                    logging.info('{}:{}'.format(name, value))

                cm = confusion_matrix(y_test.argmax(axis=1), test_predictions_baseline > 0.5)
                balanced_accuracy=((cm[1][1]/(cm[1][1]+cm[1][0])) + (cm[0][0]/(cm[0][0]+cm[0][1])))/2
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
                    'project'    : 'eclipse',
                    'feature'    : feature,
                    'classifier' : 'lstm+emb',
                    'balancing'  : BALANCING,
                    'resampling' : '-',
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
results.to_csv(cwd+'/results/{}-long-lived-bug-prediction-w-dnn-results.csv'.format(today), index_label='#')

