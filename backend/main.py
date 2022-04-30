from flask import Flask, request
from werkzeug.utils import secure_filename

import os
from pathlib import Path
import numpy as np

import tensorflow as tf

app = Flask(__name__)

MODEL_DIR = '/app/model-fruit-veg'
UPLOAD_DIR = '/app/uploads'
DATASET_DIR = '/app/datasets'

TRAIN_DIR = '${DATASET_DIR}/train'
VAL_DIR = '${DATASET_DIR}/validation'

IMG_HEIGHT = 180
IMG_WIDTH = 180

CLASS_NAMES = ['apple', 'banana', 'beetroot', 'bell pepper', 'cabbage', 'capsicum', 'carrot', 'cauliflower', 'chilli pepper', 'corn', 'cucumber', 'eggplant', 'garlic', 'ginger', 'grapes', 'jalepeno', 'kiwi',
               'lemon', 'lettuce', 'mango', 'onion', 'orange', 'paprika', 'pear', 'peas', 'pineapple', 'pomegranate', 'potato', 'raddish', 'soy beans', 'spinach', 'sweetcorn', 'sweetpotato', 'tomato', 'turnip', 'watermelon']


@app.route('/')
def home():
    return "Server is running!"


@app.route('/Classify', methods=['POST'])
def image_classify():
    model = tf.keras.models.load_model(MODEL_DIR)
    file = request.files['file']

    if file:
        filename = secure_filename(file.filename)
        filePath = os.path.join(UPLOAD_DIR, filename)
        file.save(filePath)

        img = tf.keras.utils.load_img(
            filePath, target_size=(IMG_HEIGHT, IMG_WIDTH))
        img_array = tf.keras.utils.img_to_array(img)
        img_array = tf.expand_dims(img_array, 0)  # Create a batch

        predictions = model.predict(img_array)
        score = tf.nn.softmax(predictions[0])

        result = "This image most likely belongs to {} with a {:.2f} percent confidence.".format(
            CLASS_NAMES[np.argmax(score)], 100 * np.max(score))

        print(result)
        os.remove(filePath)

        if 100 * np.max(score) > 70:
            return result

    return "Cannot be identified!"


# @app.route('/Submit', method='POST')
# def train_model():
#     model = tf.keras.models.load_model(MODEL_DIR)
#     file = request.files['file']

#     if file and allowed_file(file.filename):
#         input_class = request.args.get('class_name')
#         filename = secure_filename(file.filename)
#         filePath = pathlib.Path(TRAIN_DIR, input_class)
#         path.mkdir(parents=True)

#         file.save(pathlib.Path(filePath, filename))

#         train_dir = pathlib.Path(TRAIN_DIR)
#         val_dir = pathlib.Path(VAL_DIR)

#         return 'THANKS'
