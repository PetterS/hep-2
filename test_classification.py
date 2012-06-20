#
#
# %load_ext autoreload
# %autoreload 2
#
import scipy.io
import numpy as np
from sklearn.ensemble import RandomForestClassifier
import csv
from time import time
import cv2 as cv

from petter import ProgressBar

import features 


# Features from Matlab; not used
contents = scipy.io.loadmat('features.mat')
F = contents['F']
F_STR = contents['F_STR']

# Read in data set 
lines = []
for line in csv.reader(open('training/gt_training.csv','r'), delimiter=';') :
    lines.append(line)
CLASS = []
I = []
M = []
progress_bar = ProgressBar(len(lines), 'Reading images...')
for line in lines:
    cls = line[1]
    if cls == 'homogeneous':
        CLASS.append( 1 )
    elif cls == 'nucleolar':
        CLASS.append( 2 )
    elif cls == 'coarse_speckled':
        CLASS.append( 3 )
    elif cls == 'fine_speckled':
        CLASS.append( 4 )
    elif cls == 'centromere':
        CLASS.append( 5 )
    elif cls == 'cytoplasmatic':
        CLASS.append( 6 )
    else:
        progress_bar.progress()
        continue
    id = int(line[0])
    I.append( cv.imread('training/%03d.png' % id , 0) )
    M.append( cv.imread('training/%03d_mask.png' % id, 0) )
    
    progress_bar.progress()
	
CLASS = np.array(CLASS)


n = len(I)                       # Number of training examples
m = len(features.get(I[0],M[0])) # Number of features
print 'Feature dimension:', m

#Compute features
start = time()
F = np.zeros((n, m))
progress_bar = ProgressBar(n, 'Computing features...')
for i in range(n) :
    F[i,] = features.get(I[i],M[i])
    progress_bar.progress()
features_time = time()-start

# Split data set in half
TRAIN = range(0,n//2)
TEST  = range(n//2,n)

# Train classifier
print 'Training classifier...'
start = time()
clf = RandomForestClassifier(n_estimators=100)
clf = clf.fit(F[TRAIN,],CLASS[TRAIN])
training_time = time()-start

# Predict
print 'Predicting...'
start = time()
pred = clf.predict(F[TEST,])
true = CLASS[TEST]
test_time = time()-start

# Compute number of correct predictions
correct = len([ (x,y) for x,y in zip(true,pred) if x==y])

print 'Features time: %.1f ms per instance' %  (features_time / float(n) * 1000.0,)
print 'Training time: %.1f s' % training_time
print 'Test time: %.1f ms per instance' %  (test_time / float(len(TEST)) * 1000.0,)
print 'Accuracy: %.1f%%' % (100*float(correct)/float(len(TEST)),)
