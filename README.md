Proyecto en DJango version 

Proceso de migración de sqlite a postgress contenerizado

0.- Situarse en carpeta eccomerce  y cargar entorno virtual :
source env/Scripts/activate

1.- Conecado Django a la bd de sqlite ejecutar el siguiente comando por consola git para hacer un dump del contenido de la BD de sqlite:
python manage.py dumpdata --exclude auth.permission --exclude contenttypes --indent 2 > initial_data.json
o probar este comando:
python manage.py dumpdata --exclude auth.permission --exclude contenttypes --indent 2 | Out-File -Encoding utf8 initial_data.json

2.- Abrir con vs Code y ponerlo en codificacion UTF-8

3.- Modificar el setting.py de Django con los datos de la conexion de postgres
DATABASES = {
    'default': {
        'ENGINE': config('DB_ENGINE'),
        'NAME': config('DB_NAME'),
        'USER': config('DB_USER'),
        'PASSWORD': config('DB_PASSWORD'),
        'HOST': config('DB_HOST'),
        'PORT': config('DB_PORT'),
    }
}

4.- Meter en un .env los datos de la conexion de postgres
DB_ENGINE='django.db.backends.postgresql'
DB_NAME='djangodb'
DB_USER='django_user'
DB_PASSWORD='contraseña'
DB_HOST='127.0.0.1'
DB_PORT='5432'

5.- Realizar migracion (esto es para crear la estructura vacia en la bd de postgres ):
 python manage.py migrate



6.- Cargar el dump desde consola git:
python manage.py loaddata initial_data.json

7.- Crear super usuario (usuario para panel de admin, ya que tras la migracion el admin anterior puede pasa a ser usuario normal) para ello en consola git ejecutar:
winpty python manage.py createsuperuser


8.- Arrancar y verificar que la app de django funciona correctamente:
python manage.py runserver




Levantar proyecto dockerizado:
web + nginx
docker-compose -f web.yml -f nginx.yml up --build -d

bd:
docker compose up -d




ANOTACIONES IMPORTANTES:
*Cuando se modifican elementos de la carpeta static hay que hacer un collecstatic para que se actualice los cambios (seria ideal ver si se puede meter como comando inicial en el docker compose para que cada vez que se levante haga dicha actualización por si hay algun cambio pendiente):
python manage.py collectstatic -->  Ojo! que es interactivo, hay que escribir 'yes' para confirmar