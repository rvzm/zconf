# zConf ZNC Sistema De Gestion De usuario
# v0.7.7

Para Soporte, por favor visita irc.fukin.tech canal: #znc,
Tambien al email rvzm@protonmail.com, O en la web https://fukin.tech/support/

## Agradecimiento espacial a PentSec - Deliri0m en freenode

# Requerimientos
 - eggdrop
 `- Probado sobre 1.8.0rc-4, Pero funciona perfectmente en 1.6.21
 - Cuenta ZNC Admin con los modulos Contropanel y Blockuser activados
 `- La cuenta administradora debera llamarse zconf
 - sudo apt install libsqlite3-tcl tcl8.6-tdbc-sqlite3
 - Comandos Telnet o dcc Obligatorios -> .+bot znc .+host znc *!znc@znc.in .chattr znc +f

## Comandos de Usuarios
comandos | Descripcion
---------|-------
request  | Peticion por una znc account.
approve  | Activa tu cuenta con el codigo previamente dado.
status   | Visualizar el Estado actual del servidor zConf.
info     | Visualizar informacion de zConf, incluyendo como acceder a zConf web.
help     | Obtienes ayuda sobre zConf
version  | Visualiza la version de zConf
admins   | lista los administradores de zConf
access   | Visualizar el zConf ZNC "puntos de acceso" Y como conectarte
pwdgen   | Generar una contraseña aleatoria utilizando la longitud de contraseña predeterminada

## Comandos de Administradores
comandos  | Descripciones
----------|-------
freeze    | Bloque una cuenta.
restore   | Desbloquea una cuenta
purge     | Borra una cuenta
listusers | Lista todos los usuarios en la ZNC
lastseen  | Muestra la ultima coneccion de los usuarios a la znc
pubreg    | Activa o desactiva la registracion de usuario on/off
admin     | Administra los administradores de zConf
-> add    | Añade a zConf un administrador
-> list   | Lista todos los administradores disponibles
