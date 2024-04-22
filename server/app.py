from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from flask_mysqldb import MySQL
from ia.predictions_yolo_image import main_IA
import os
import jwt
import uuid
from math import radians


app = Flask(__name__)
CORS(app)

app.secret_key = b'_5#y2L"F4Q8z\n\xec]/'

app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = 'PzR(3^n77Gw4:v'
app.config['MYSQL_DB'] = 'leafdiseases'
app.config['MYSQL_CURSORCLASS'] = 'DictCursor'  # Pour récupérer les résultats sous forme de dictionnaires

app.config['UPLOAD_FOLDER'] = 'images'

mysql = MySQL(app)

def get_users(user_id):
    try:
        cursor = mysql.connection.cursor()
        cursor.execute("SELECT Fname, Lname, email, password FROM users WHERE user_id=%s", (user_id,))
        users = cursor.fetchall()
        print(users)
        cursor.close()
        return jsonify(users)
    except Exception as e:
        return jsonify({"error": str(e)})

def tokenSessionOk(token):
     # Vérifiez si le token est présent dans l'en-tête Authorization
    authorization_header = token
    if authorization_header and authorization_header.startswith('Bearer '):
        token = authorization_header.split(' ')[1]
        try:
            # Décodez le token en utilisant la clé secrète
            decoded_token = jwt.decode(token, app.secret_key, algorithms=['HS256'])
            # Récupérez l'ID utilisateur à partir du token décodé
            user_id = decoded_token['user_id']
            return True
        except jwt.ExpiredSignatureError:
            # Le token a expiré
            return False
        except jwt.InvalidTokenError:
            return False
    else:
        # Le token est manquant dans l'en-tête Authorization
        return False

def get_id(tokenCrypt):
    token = request.headers.get('Authorization').split(' ')[1]
    decoded_token = jwt.decode(token, app.secret_key, algorithms=['HS256'])
    return decoded_token['user_id']

def get_diseases_id(name):
    diseases_dict = {
    "Septoria": "16b4f429-9b1b-43c7-8369-fdb69a4a96b5",
    "Mosaic Virus": "3aaf73fc-4df3-4ad4-b6aa-f35dfcb899f5",
    "Not leaf": "3fe6b59b-1d88-4e11-a17e-0a46ccf46c1f",
    "Late Blight": "4f358108-97a3-44c7-9b42-d44f816c6f12",
    "Early Blight": "76c3a6a6-b06e-44f4-a6b3-27f74e20a0eb",
    "Healthy": "948a27c3-fdb7-458e-97fc-59febbfc1b1d",
    "Leaf Mold": "a550cbf3-4090-4f59-84a3-d68ef40ab5c3",
    "Bacterial spot": "b87b0d76-8cc9-44cf-9a3c-032b5b94634a",
    "Spider Mites": "d34cb9c4-82ec-4a2f-87f4-89bfaa5a14cb",
    "Yellow Leaf Curl Virus": "eeb86926-f4ef-4155-8a4a-bad3771cf784",
    "Target Spot": "f48b537e-d084-4dc1-8f72-2df68e144c47"
    }
    return diseases_dict[name]


@app.route('/api/login', methods=['POST'])
def login():
    data = request.json
    email = data['email']
    password = data['password']

    print(email, password)

    cursor = mysql.connection.cursor()
    cursor.execute("SELECT user_id FROM users WHERE email=%s AND password=%s", (email, password))
    user_id = cursor.fetchone()
    cursor.close()

    print(user_id)
    if user_id is None:
        print("Pb connection")
        return jsonify({"error": "Identifiants incorrects"}), 401 
    else:
        token = jwt.encode({'user_id': user_id["user_id"]}, app.secret_key, algorithm='HS256')
        print(token)
        return jsonify({"message": "Connexion réussie", "token": token})

@app.route('/api/register', methods=['POST'])
def register():
    data = request.json
    id=str(uuid.uuid4())
    Fname = data['Fname']
    Lname = data['Lname']
    email = data['email']
    password = data['password']

    print(id, Fname, Lname, email, password)

    cursor = mysql.connection.cursor()
    cursor.execute("INSERT INTO users (user_id, Fname, Lname, email, password) VALUES (%s, %s, %s, %s, %s)", (id, Fname, Lname, email, password))
    mysql.connection.commit()
    cursor.close()

    return jsonify({"message": "Utilisateur enregistré avec succès"})

@app.route('/api/homepage', methods=['POST'])
def hompage():
    tokenSessionOk(request.headers.get('Authorization'))
    
    return jsonify({"message": "Données reçues avec succès"})

@app.route('/api/showProfile', methods=['POST'])
def showProfile():
    
    if(tokenSessionOk(request.headers.get('Authorization'))):
        id = get_id(request.headers.get('Authorization'))
        print(id)
        cursor = mysql.connection.cursor()
        cursor.execute("SELECT Fname, Lname, email, password FROM users WHERE user_id=%s", (id,))
        user = cursor.fetchone()
        cursor.close()
        print(user)
        return jsonify({"data": user})
    else:
        return jsonify({"error": "Token invalide"})

@app.route('/api/modifyProfile', methods=['POST'])
def modifyProfile():
    data = request.json
    id = get_id(request.headers.get('Authorization'))
    Fname = data['Fname']
    Lname = data['Lname']
    email = data['email']
    password = data['password']

    cursor = mysql.connection.cursor()
    cursor.execute("UPDATE users SET Fname=%s, Lname=%s, email=%s, password=%s WHERE user_id=%s", (Fname, Lname, email, password, id))
    mysql.connection.commit()
    cursor.close()
    print('token modif data', id, Fname, Lname, email, password)

    return jsonify("user")

@app.route('/api/historique', methods=['POST'])
def historique():

    print(tokenSessionOk(request.headers.get('Authorization')))
    
    if (tokenSessionOk(request.headers.get('Authorization'))):
        print("Token valide")
        id = get_id(request.headers.get('Authorization'))
        print("On est bien : ", id)
        cursor = mysql.connection.cursor()
        cursor.execute("SELECT s.image, s.date_scan, d.name, d.cure FROM scan s JOIN diseases_bank d ON s.diseases_id = d.diseases_id WHERE s.user_id = %s", (id,))
        scans = cursor.fetchall()
        cursor.close()

        return jsonify({"message": scans})
    else:
        print("Token invalide")
        return jsonify({"error": "Token invalide"})

@app.route('/api/diseases', methods=['POST'])
def diseases():
    if (tokenSessionOk(request.headers.get('Authorization'))):
        print("Token valide")
        cursor = mysql.connection.cursor()
        cursor.execute("SELECT name, description, cure, image, plant FROM diseases_bank WHERE cure IS NOT NULL")
        diseases = cursor.fetchall()
        cursor.close()
        print(diseases)
        return jsonify({"data": diseases})
    else:
        print("Token invalide")
        return jsonify({"error": "Token invalide"})

@app.route('/api/scan', methods=['POST'])
def scan():
    # Vérifier si un fichier a été envoyé
    if 'images' not in request.files:
        print("Aucune image n'a été envoyée")
        return jsonify({"error": "Aucune image n'a été envoyée"}), 400

    image = request.files['images']
    latitude = request.form.get('latitude')
    longitude = request.form.get('longitude')
    print("latitude", latitude)
    print("longitude", longitude)

    # Vérifier si le fichier a un nom valide
    if image.filename == '':
        print("Le fichier n'a pas de nom")
        return jsonify({"error": "Le fichier n'a pas de nom"}), 400

    # Générer un nom de fichier unique avec UUID
    image_extension = image.filename.split('.')[-1]  # Obtenir l'extension de l'image
    new_image_filename = str(uuid.uuid4()) + '.' + image_extension

    # Enregistrer l'image dans un dossier sur le serveur avec le nouveau nom
    image.save('image/' + new_image_filename)

    print("avant l'appel de la fonction IA")
    result = main_IA(new_image_filename)
    print("Apres l'appel de la fonction IA")

    print(result)
    if(result == []):
        print("pas de feuilles")
        result = "Not leaf"
    else:
        print("des feuilles")
        result = result[0]

    print(get_diseases_id(result))
    date = request.form.get('date')

    # Insérer les données dans la base de données
    id_scan = str(uuid.uuid4())
    cursor = mysql.connection.cursor()
    cursor.execute("INSERT INTO scan (scan_id, diseases_id, user_id, image, longitude, latitude, date_scan) VALUES (%s, %s, %s, %s, %s, %s, %s)", (id_scan, get_diseases_id(result), get_id(request.headers.get('Authorization')), new_image_filename, longitude, latitude, date))
    mysql.connection.commit()
    cursor.close()

    # Répondre avec un message de succès
    return jsonify({"message": "Image enregistrée avec succès"}), 200

@app.route('/api/diseases_names', methods=['GET'])
def get_diseases():
    try:
        # Connect to the database
        cursor = mysql.connection.cursor()
 
        # Execute query to fetch all disease names
        cursor.execute("SELECT name FROM diseases_bank WHERE cure IS NOT NULL")
        diseases = cursor.fetchall()
 
        # Close cursor and database connection
        cursor.close()
 
        # Extract names from the query result
        disease_names = [disease["name"] for disease in diseases]
 
        return jsonify({"disease_names": disease_names})
    except Exception as e:
        return jsonify({"error": str(e)})
 
@app.route('/api/get_locations', methods=['POST'])
def get_coordinates_in_radius():
    data = request.get_json()
    lat = float(data.get('latitude'))
    lng = float(data.get('longitude'))
    disease_list = data.get('disease_list', [])
    print(disease_list, lat, lng)
 
    # Approximation of Earth's radius in meters
    R = 6371000.0
 
    # Convert latitude and longitude to radians
    lat1 = radians(lat)
    lng1 = radians(lng)
 
    coordinates_in_radius = []
 
    try:
        cursor = mysql.connection.cursor()
 
        if not disease_list:  # If disease_list is empty, select all diseases
            cursor.execute("SELECT diseases_id FROM diseases_bank")
            diseases = cursor.fetchall()
        else:
            # Fetch disease IDs based on names in the disease_list
            cursor.execute("SELECT diseases_id FROM diseases_bank WHERE name IN %s", (tuple(disease_list),))
            diseases = cursor.fetchall()
 
        for disease in diseases:
            disease_id = disease['diseases_id']
 
            # Retrieve all coordinates within the radius for this disease
            cursor.execute("SELECT latitude, longitude FROM scan WHERE diseases_id = %s", (disease_id,))
            coordinates = cursor.fetchall()
 
            for coordinate in coordinates:
 
                # If the distance is less than or equal to the specified radius,
                # add the coordinates to the list of coordinates within the radius
                coordinates_in_radius.append((coordinate['latitude'], coordinate['longitude']))
 
        cursor.close()
        print(coordinates_in_radius)
 
        return jsonify({"coordinates": coordinates_in_radius})
 
    except Exception as e:
        print("Error retrieving coordinates:", str(e))
        return jsonify({"error": "Failed to retrieve coordinates"}), 500

@app.route('/image/<path:nom_image>')
def afficher_image(nom_image):
    return send_from_directory('image', nom_image)

from ia.test import main

@app.route('/api/test')
def test():
    data = "mon image"
    print(print(main(data)))
    print("2")
    return "Bababoy"


@app.route('/')
def hello_world():
    return 'Hello, Flask!'

if __name__ == '__main__':
    app.run(debug=True)