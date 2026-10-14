# DermaAI: AI-Powered Skin Care & Dermatology Guide App

> Final Year Project, BS Computer Science (Session 2022-2026)
> Quaid-i-Azam University, Islamabad, Department of Computer Science

DermaAI is a Flutter mobile app that gives early skin-care guidance from your phone. Snap a photo, describe your symptoms or pick a condition, and get an instant AI suggestion with a doctor-style recommendation.

> **Disclaimer:** DermaAI provides educational guidance only. It is **not** a medical diagnosis. Please consult a dermatologist for any skin concern.

## Screenshots

| AI prediction | Disease list | Admin panel |
|:---:|:---:|:---:|
| <img src="screenshots/prediction.png" width="200"> | <img src="screenshots/disease-list.png" width="200"> | <img src="screenshots/admin-panel.png" width="200"> |

## The Problem

- Skin problems such as acne, rashes, infections and allergies are very common.
- Dermatologists are costly, far away or booked for weeks, and 70%+ of people delay care.
- Online skin advice is often contradictory, and existing apps only inform. None analyse the user's own skin image.

## Features

- **Three ways to ask:** image upload (camera or gallery), text symptoms in plain English, or a disease list of 15 conditions
- **AI prediction:** disease name, confidence score and a doctor's recommendation
- **Secure login** with Firebase Authentication
- **Chat history** stored in Cloud Firestore
- **Admin dashboard:** usage stats, users, and model updates through Firebase Storage
- **On-device model** using TensorFlow Lite

## How It Works

```
User input  ->  Preprocessing  ->  DenseNet121 (TFLite)  ->  Output
(image / text /   (resize 224x224,    (ImageNet pretrained,     (disease name,
 disease list)     normalize [0,1],    fine-tune last 15         confidence score,
                   augment, 70/15/15   layers, Dense 512->256,   recommendation)
                   split)              Softmax x15)
```

Architecture: **Flutter app <-> Flask API <-> Firebase** (Authentication, Firestore chat history, Storage for model updates).

## Tech Stack

Flutter, Dart, Firebase, TensorFlow Lite, Keras, Python, Google Colab, OpenCV, NumPy, Flask, Android

## Dataset

[MediQA-M3G](https://sites.google.com/view/mediqa2024/mediqa-m3g) (Multilingual & Multimodal Medical Answer Generation), from the MEDIQA-M3G 2024 shared task. 842 entries, 2,450+ images. Distributed for **academic use only**; the dataset itself is not included in this repository.

## Results

| Model | Test Accuracy | BERTScore F1 | Cosine Similarity |
|---|:---:|:---:|:---:|
| MobileNetV2 | 40.52% | 0.9089 | 0.6360 |
| NASNet-Mobile | 39.87% | 0.9079 | 0.6276 |
| **DenseNet121** | **45.75%** | **0.9138** | **0.6598** |

DenseNet121 was selected as the final model (training accuracy 60.88%, 15 disease classes).

## Project Structure

<!-- Replace with your real folders, for example: -->
```
[app folder]/        Flutter mobile app
[backend folder]/    Flask API
[model folder]/      Training notebook and TFLite model
```

## Getting Started

> Adjust the commands below to match your repository.

**Prerequisites:** Flutter SDK, Python 3.x, a Firebase project (Authentication, Firestore, Storage), an Android device or emulator.

```bash
# 1. Clone
git clone [your repository URL]
cd [repository name]

# 2. Run the backend
cd [backend folder]
pip install -r requirements.txt
python [main file].py

# 3. Run the app
cd [app folder]
flutter pub get
flutter run
```

Add your own Firebase configuration (for example `google-services.json`) before running the app.

## Future Work

- More diseases and larger, skin-tone-diverse datasets
- Urdu and multilingual support
- Explainable AI heatmaps
- Telemedicine and clinical validation

## Author

**Muhammad Anique Azhar**, BS Computer Science, Quaid-i-Azam University, Islamabad
Supervisor: **Dr. Nadia Saeed**, Department of Computer Science

Presented at InnovateX 26.

## License

The code is released for academic and educational use. The MediQA-M3G dataset is under its own academic license. [Choose a license for your code, for example MIT, or remove this line.]
