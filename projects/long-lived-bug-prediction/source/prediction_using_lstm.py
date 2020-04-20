"""Predict a long lived bug."""
import os
import re
import matplotlib as mpl
import matplotlib.pyplot as plt
import nltk
from nltk.corpus import stopwords
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.metrics import confusion_matrix

import tensorflow as tf
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
from tensorflow import keras

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
mpl.rcParams['figure.figsize'] = (12, 10)
COLORS = plt.rcParams['axes.prop_cycle'].by_key()['color']
nltk.download('stopwords')
print('1. Setup completed')

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
    text = ' '.join(word for word in text.split()
                    if word not in english_stopwords)
    return text


def read_reports(filename):
    """Read a bug reports file.

    Parameters
    ----------
    filename: string
        A datafile name.

    """
    data = pd.read_csv(filename, encoding='utf8', sep=',', parse_dates=True,
                       low_memory=False)

    data['class'] = data['bug_fix_time'].apply(lambda t: 1 if t > 365 else 0)
    data = data[['short_description', 'long_description', 'class']]
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

def make_model(output_bias=None, input_dim=50000, output_dim=100,
               input_length=50000):
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
            keras.layers.Embedding(input_dim=input_dim, output_dim=output_dim,
                                   input_length=input_length),
            keras.layers.SpatialDropout1D(0.2),
            keras.layers.LSTM(100, dropout=0.2, recurrent_dropout=0.2),
            keras.layers.Dense(2, activation='sigmoid')
        ]
     )

    model.compile(
            optimizer=keras.optimizers.Adam(lr=1e-3),
            loss=keras.losses.BinaryCrossentropy(),
            metrics=METRICS
    )

    return model


# constants
cwd = os.getcwd()
DATAFILE = cwd + '/datasets/20190917_gcc_bug_report_data.csv'
FEATURE = 'long_description'
MAX_NB_WORDS = 50000
MAX_NB_TERMS = [100, 150, 200, 250, 300]
EMBEDDING_DIM = 100
EPOCHS = 20
BATCH_SIZE = 1024

reports = read_reports(DATAFILE)
print('2. Bug reports file read.')
neg, pos = np.bincount(reports['class'])
total = neg + pos
print('2.1 Reports - Total: {} Positive: {} ({:.2f}% of total)'.format(
    total, pos, 100 * pos / total))
reports = clean_reports(reports, FEATURE)
print('3. Bug reports {} cleaned.'.format(FEATURE))

tokenizer = Tokenizer(num_words=MAX_NB_WORDS,
                      filters='!"#$%&()*+,-./:;<=>?@[\]^_`{|}~',
                      lower=True)
early_stopping = tf.keras.callbacks.EarlyStopping(
    monitor='val_accuracy',
    verbose=1,
    patience=10,
    mode='max',
    restore_best_weights=True
)
tf.autograph.experimental.do_not_convert(
    func=None
)

for max_nb_terms in MAX_NB_TERMS:
    tokenizer.fit_on_texts(reports['long_description'].values)
    word_index = tokenizer.index_word
    X = tokenizer.texts_to_sequences(reports['long_description'].values)
    X = pad_sequences(X, maxlen=max_nb_terms)
    print('4. Data tokenized')
    print('4.1 Found {} unique tokens, using {} terms.'.format(len(word_index), max_nb_terms))
    print('4.2 Shape of data tensor:', X.shape)

    Y = pd.get_dummies(reports['class']).values
    print('4.2 Shape of label tensor:', Y.shape)
    print('5. Data pre-processed')

    print('6. Spliting data started')
    X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.2,
                                                    random_state=42)
    X_train, X_val, Y_train, Y_val = train_test_split(X_train, Y_train,
                                                  test_size=0.2,
                                                  random_state=42)
    print('Training shape    :', X_train.shape, Y_train.shape)
    print('Validation shape  :', X_val.shape, Y_val.shape)
    print('Test shape        :', X_test.shape, Y_test.shape)
    print('7. Spliting data concluded')

    model   = make_model(input_length=X.shape[1], output_dim=max_nb_terms)
    model.layers[-1].bias.assign([0.0, 0.0])
    history = model.fit(
        X_train,
        Y_train,
        batch_size=BATCH_SIZE,
        epochs=5,
        validation_data=(X_val, Y_val),
        callbacks=[early_stopping],
        verbose=0
    )
    train_predictions_baseline = model.predict_classes(X_train
                                                   , batch_size=BATCH_SIZE)
    test_predictions_baseline  = model.predict_classes(X_test
                                                   , batch_size=BATCH_SIZE)

    baseline_results = model.evaluate(X_test, Y_test, batch_size=BATCH_SIZE, verbose=0)
    for name, value in zip(model.metrics_names, baseline_results):
        print(name, ': ', value)

    cm = confusion_matrix(Y_test.argmax(axis=1), test_predictions_baseline > 0.5)
    balanced_accuracy=((cm[1][1]/(cm[1][1]+cm[1][0])) + (cm[0][0]/(cm[0][0]+cm[0][1])))/2
    print('balanced accuracy : ', balanced_accuracy)

    columns  = ['project', 'feature', 'classifier']
    columns += ['balancing', 'resampling', 'metric', 'threshold']
    columns += ['train_size', 'train_size_class_0', 'train_size_class_1']
    columns += ['test_size', 'test_size_class_0', 'test_size_class_1']
    columns += model.metrics_names
    columns += ['sensitivity', 'specificity', 'balanced_acc']
    columns += ['fmeasure']
    metrics = pd.DataFrame(columns=columns)

    loss = baseline_results[0] 
    tp = baseline_results[1]
    fp = baseline_results[2]
    tn = baseline_results[3]
    fn = baseline_results[4]
    accuracy = baseline_results[5]
    sensitivity = tp / (tp + fn) 
    specificity = tn / (tn + fp)
    precision = baseline_results[6]
    recall = baseline_results[7]
    fmeasure = (2 * precision * recall) / (precision + recall)
    auc = baseline_results[8]

    metric = {
        'project'    : 'gcc',
        'feature'    : 'long_description',
        'classifier' : 'lstm',
        'balancing'  : 'unbalanced',
        'resampling' : '-',
        'metric'     : 'val_acc',
        'threshold': 365,
        'train_size': Y_train.shape[0],
        'train_size_class_0': Y_train.shape[0],
        'train_size_class_1': Y_train.shape[0],
        'test_size': Y_test.shape[0],
        'test_size_class_1': Y_test.shape[0],
        'test_size_class_0': Y_test.shape[0],
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
        'fmeasure': fmeasure
    }
    metrics = metrics.append(metric, ignore_index=True)
    
metrics.to_csv('lstm_metrics.csv', index_label='#')

