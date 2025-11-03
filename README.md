
# Django Ecommerce



Proyecto en DJango
-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
Proceso de migración de sqlite a postgress contenerizado en Local, antes de pasar al servidor para wue en el servidor ya esté con postgres

0.- Situarse en carpeta eccomerce  y cargar entorno virtual :

```bash
source env/Scripts/activate  
```


1.- Conecado Django a la bd de sqlite ejecutar el siguiente comando por consola git para hacer un dump del contenido de la BD de sqlite:
```bash
python manage.py dumpdata --exclude auth.permission --exclude contenttypes --indent 2 > initial_data.json  
```
o probar este comando que ya tiene formato utf8:

```bash
python manage.py dumpdata --exclude auth.permission --exclude contenttypes --indent 2 | Out-File -Encoding utf8 initial_data.json  
```

2.- Abrir con vs Code y ponerlo en codificacion UTF-8

3.- Modificar el setting.py de Django con los datos de la conexion de postgres

```bash

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

```


4.- Meter en un .env los datos de la conexion de postgres
```bash
DB_ENGINE='django.db.backends.postgresql'
DB_NAME='djangodb'
DB_USER='django_user'
DB_PASSWORD='contraseña'
DB_HOST='127.0.0.1'
DB_PORT='5432'  
```


5.- Realizar migracion (esto es para crear la estructura vacia en la bd de postgres ):
 
 ```bash
python manage.py migrate
```


6.- Cargar el dump desde consola git (yo la uso porque acepta comandos linux (uso Windows)):

```bash
python manage.py loaddata initial_data.json  
```


7.- Crear super usuario (usuario para panel de admin, ya que tras la migracion el admin anterior puede pasa a ser usuario normal) para ello en consola git ejecutar:

```bash
winpty python manage.py createsuperuser  
```



8.- Arrancar y verificar que la app de django funciona correctamente:
python manage.py runserver




# Levantar proyecto dockerizado:
web + nginx
```bash
docker-compose -f web.yml -f nginx.yml up --build -d  
```

bd:
```bash
docker compose up -d  
```


-------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

# Elementos estáticos
ANOTACIONES IMPORTANTES:
Cuando se modifican elementos de la carpeta static (si no está dockerizado) hay que hacer un collecstatic para que se actualice los cambios 

```bash
python manage.py collectstatic
```

Por otro lado cuando se usa docker al construir la imagen se introduce la instrucción 

```bash
RUN python manage.py collectstatic --noinput:  
```
Por lo que hay que hacer build por cada cambio en static, ya sea en un .css o al meter una imagen o modificar un html de dicha carpeta static

-------------------------------------------------------------------------------------------------------------------------------------

# Instrucciones iniciar aplicacion dockerizada en local sin django dockerizado con bd postgres:

```bash

cd postgres
```
(Comentar la red externa en el yml de db-dev.yml si no lo está quitado y levantar el contenedor)

```bash
docker compose -f db-dev.yml --env-file .env-dev up -d

cd..

```
2. Cambiar en el .env la variable DB_HOST
```bash
cd eccomerce
```
(cambiar en el .env la variable a DB_HOST='127.0.0.1')

```bash
source env/Scripts/activate

python manage.py collectstatic

python manage.py runserver



```


-------------------------------------------------------------------------------------------------------------------------------------------------
# Instrucciones iniciar aplicacion dockerizada en local CON django dockerizado:
```bash
cd postgres  
```
(cambiar en el .env la variable a DB_HOST=db)
```bash
docker compose -f web-dev.yml --env-file .env-dev up -d

cd..

cd eccomerce

docker-compose -f web.yml-dev -f nginx-dev.yml up --build -d

cd   
```

-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------


# Anulado de Registro de usuario:
```bash
-accounts --> urls.py comentada linea de URL
-forgotPassWord.html-->comentada linea: {#         <p class="text-center mt-4">No tienes una cuenta? <a href="{% url 'register' %}">Registrate</a></p> #}
-login.html-->comentada linea:  {#     <p class="text-center mt-4">No tienes una cuenta? <a href="{% url 'register' %}">Registrate</a></p> #}
-resetPassword.html-->comentada linea: {# <p class="text-center mt-4">No tienes una cuenta? <a href="{% url 'register' %}">Registrate</a></p> #}
-navbar-->comentada linea: {# href="{% url 'register' %}"> Registrar</a> #}

```

Comentada función register de accounts/views.py y sustituida por esta:
```bash
def register(request):
    """
    Esta función deshabilita el registro de nuevos usuarios
    y redirige a la página de inicio de sesión.
    """
    messages.info(request, 'El registro de nuevos usuarios no está permitido en este momento.')
    return redirect('login') # Puedes redirigir a 'login' o a la página principal de tu tienda  
```


-------------------------------------------------------------------------------------------------------------------------------------------------

Levantar como proyecto en servidor(opción más recomendable):
docker compose   --project-name ecommerce-django   -f /srv/docker/postgres/db.yml   -f /srv/docker/ecommerce-django/web.yml   -f /srv/docker/nginx-proxy/nginx.yml   up -d