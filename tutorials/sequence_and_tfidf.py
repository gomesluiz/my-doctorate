# -*- coding: utf-8 -*-
"""
Created on Thu Mar  5 11:36:32 2020

@author: luizgomes
"""

from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
from tensorflow import keras

def vectorize_text(text, max, mode='sequence'):
    
    tokenizer = Tokenizer(num_words=1000
                          , filters='!"#$%&()*+,-./:;<=>?@[\]^_`{|}~'
                          , lower=True)

    tokenizer.fit_on_texts(text)
    if mode == 'tfidf':
        X = tokenizer.texts_to_matrix(text, mode="tfidf")
        X = X[:, 1:max+1]
    else:
        X = tokenizer.texts_to_sequences(text)
        X = pad_sequences(X, maxlen=max)
    
    return X

docs = ['Well done!',
        'Good work',
        'Great effort',
        'nice work',
        'Excellent!',
        'Weak',
        'Poor effort!',
        'not good',
        'poor work',
        'Could have done better']

#docs = ['a b b c c c!', 'a a a b']
labels = [1, 1, 1, 1, 1, 0, 0, 0, 0, 0]

print(vectorize_text(docs, max=10, mode='sequence'))
print(vectorize_text(docs, max=10, mode='tfidf'))

# pad documents to a max length of 4 words
max_length  = 4

model = Sequential()
model.add(Embedding(vocab_size, 8, input_length=max_length))
model.add(Flatten())
model.add(Dense(1, activation='sigmoid'))
# compile the model
model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])
print(model.summary())

# fit model
model.fit(padded_docs, labels, epochs=50, verbose=True)
loss, accuracy = model.evaluate(padded_docs, labels, verbose=True)
print('Accuracy %f' % (accuracy * 100))
