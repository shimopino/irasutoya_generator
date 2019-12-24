from flask import Flask,render_template,request,send_file
import socket
import io
import os
import base64

import numpy as np
from PIL import Image

import torch
import torch.nn as nn
from transformers.modeling_bert import BertModel
from transformers.tokenization_bert_japanese import BertJapaneseTokenizer
from utils import load_model

device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')

bert_model_name = 'bert-base-japanese'
tokenizer = BertJapaneseTokenizer.from_pretrained(bert_model_name)
bert_model = BertModel.from_pretrained(bert_model_name)

text2image_model_name = os.path.abspath('./models/netG_epoch_200.pth')
netG = load_model(text2image_model_name)
netG = netG.to(device=device)
netG.eval()

app = Flask(__name__)


def input_to_sentence_tensor(text):
    tokens_id = tokenizer.encode(text, return_tensors="pt")
    w, s = bert_model(tokens_id)
    return s


@app.route("/")
def index():
    try:
        host_name = socket.gethostname()
        host_ip = socket.gethostbyname(host_name)
        return render_template('index.html')
    except:
        return render_template('error.html')


@app.route("/show_img", methods=["POST"])
def show_img():
    input_text = request.form["input"]

    # try:
    # input_text = request['caption']
    sentence_embedding = input_to_sentence_tensor(input_text)
    sentence_embedding = sentence_embedding.to(device)

    noize_vector = torch.FloatTensor(sentence_embedding.size(0), 100)
    noize_vector = noize_vector.to(device)
    noize_vector.data.normal_(0, 1)

    with torch.no_grad():
        _, fake_img, mu_, logvar_ = netG.forward(sentence_embedding, noize_vector)
        fake_img_numpy = fake_img.cpu().detach().squeeze(0).numpy().transpose((1,2,0))
        img_pil = Image.fromarray((fake_img_numpy*255 / np.max(fake_img_numpy)).astype('uint8'))

    # create file-object in memory
    file_object = io.BytesIO()

    # write PNG in file-object
    img_pil.save(file_object, 'PNG')

    # move to beginning of file so `send_file()` it will read from start    
    file_object.seek(0)

    data_uri = base64.b64encode(file_object.read()).decode('ascii')

    return render_template('index.html', data_uri=data_uri)

    # return render_template('result.html', sentence_mean=mean_str, sentence_std=std_str)
    # except:
    #     return render_template('error.html')


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)