# Documentación de Avances del Backend y Guía de Pruebas

Esta sección describe detalladamente las funcionalidades del backend desarrolladas por cada miembro del equipo, junto con las guías paso a paso para probar y verificar el funcionamiento de cada endpoint.

---

## 1. Josué: Arquitectura, Motor Interno y Control de Inventario

### 📋 Descripción de Avances
Josué estuvo a cargo de la arquitectura, el núcleo del sistema y la gestión de inventario:
* **Diseño y Setup:** Modelado UML, creación de las tablas SQL en MariaDB y configuración de la conexión (`conexion.php`) utilizando variables de entorno (`.env`).
* **Verificación de Stock (`verificar_stock.php`):** Endpoint de lectura para consultar la disponibilidad de insumos en tiempo real. Permite al frontend determinar si debe bloquear botones de toppings o productos agotados.

---

### 🧪 Guía de Pruebas: Verificación de Stock

#### Paso 1: Insertar el dato de prueba
Teniendo nuestras tablas creadas, inyectamos un insumo de prueba directamente en la base de datos para verificar la respuesta del endpoint. Ejecuta la siguiente sentencia SQL en MySQL Workbench / phpMyAdmin:

```sql
INSERT INTO insumos (nombre, tipo, stock_actual) 
VALUES ('Helado de Vainilla', 'Sabor', 50);
```

#### Paso 2: Consumir el Endpoint de Inventario
Una vez insertado el registro en la base de datos, probamos la API encargada de enviar la información del stock al frontend ingresando la siguiente URL en el navegador o cliente HTTP:

```http
GET http://localhost:8080/backend/src/verificar_stock.php
```

#### Resultado Esperado
Deberías recibir una respuesta HTTP `200 OK` con un cuerpo JSON estructurado de la siguiente forma:

```json
{
  "estado": "exito",
  "mensaje": "Inventario recuperado",
  "datos": [
    {
      "id_insumo": 1,
      "nombre": "Helado de Vainilla",
      "tipo": "Sabor",
      "stock_actual": 50,
      "disponible": 1
    }
  ]
}
```

---

## 2. Camily: Interfaz del Kiosko (Flujo del Cliente)

### 📋 Descripción de Avances
Camily implementó el flujo principal de entrada de pedidos para los clientes en la pantalla táctil / kiosko:
* **Obtención del Menú (`obtener_menu.php`):** Endpoint de lectura que consulta la tabla de productos para retornar el catálogo completo de dips, sundaes y frappés hacia la pantalla del kiosko.
* **Creación de Pedidos (`crear_pedido.php`):** Endpoint de escritura que recibe la orden seleccionada por el cliente, procesa la información y la almacena en la base de datos.

---

### 🧪 Guía de Pruebas: Menú y Creación de Pedidos

Para probar los archivos `obtener_menu.php` y `crear_pedido.php`, sigue estos pasos utilizando PHP + MariaDB y un cliente para peticiones HTTP como Postman.

#### 1. Levantar el servidor PHP y MariaDB
Si utilices XAMPP:
1. Abre el panel de control de XAMPP.
2. Inicia los servicios: **Apache** y **MySQL**.
3. Asegúrate de colocar el proyecto en la ruta local:
   `C:\xampp\htdocs\ICE-CREAM-SHOP-MANAGEMENT\`
4. Estructura requerida de carpetas/archivos:
   ```text
   ICE-CREAM-SHOP-MANAGEMENT/
   ├── conexion.php
   ├── obtener_menu.php
   └── crear_pedido.php
   ```

#### 2. Importar la Base de Datos
1. Accede a phpMyAdmin: `http://localhost/phpmyadmin`
2. Crea o importa la base de datos de la heladería y verifica que existan las tablas principales:
   * `categorias`
   * `productos`
   * `pedidos`
   * `detalle_pedidos`
3. Asegúrate de que la tabla `productos` tenga al menos un par de registros de prueba.

#### 3. Probar la consulta del Menú (GET)
Abre directamente en tu navegador la siguiente URL:

```http
GET http://localhost/ICE-CREAM-SHOP-MANAGEMENT/obtener_menu.php
```

##### Resultado Esperado
Si la conexión y la consulta son correctas, el navegador retornará un JSON con la lista de productos:

```json
[
  {
    "id_producto": 1,
    "nombre": "Frappé de Chocolate",
    "categoria": "Frappes",
    "precio_base": "4.50"
  },
  {
    "id_producto": 2,
    "nombre": "Sundae de Fresa",
    "categoria": "Sundaes",
    "precio_base": "3.50"
  }
]
```
> *Esto confirma la comunicación: Frontend → GET → PHP → MariaDB → PHP → JSON.*

#### 4. Probar la creación de un Pedido (POST con Postman)
1. Abre **Postman** y crea una nueva petición de tipo **POST**:
   ```http
   POST http://localhost/ICE-CREAM-SHOP-MANAGEMENT/crear_pedido.php
   ```
2. Configura los **Headers**:
   * `Content-Type`: `application/json`
3. Configura el **Body** (selecciona `raw` → `JSON`) e ingresa la estructura de la orden:
   ```json
   {
     "identificador_cliente": "0951234567",
     "productos": [
       {
         "id_producto": 1,
         "cantidad": 2
       },
       {
         "id_producto": 3,
         "cantidad": 1
       }
     ]
   }
   ```
4. Haz clic en **Send**.

##### Resultado Esperado
Deberías recibir una respuesta de éxito confirmando la creación del pedido:

```json
{
  "success": true,
  "message": "Pedido enviado exitosamente",
  "id_pedido": 15
}
```

#### 5. Verificación en Base de Datos
Para corroborar la persistencia de datos:
1. Ingresa a **phpMyAdmin** (`http://localhost/phpmyadmin`).
2. Consulta la tabla `pedidos` y verifica la inserción del nuevo registro con su `id_pedido`, `identificador_cliente`, `estado` y `total_pagar`.
3. Consulta la tabla `detalle_pedidos` y verifica los items vinculados (`id_detalle`, `id_pedido`, `id_producto`, `cantidad`, `subtotal`).

---

## 3. Génesis: Panel del Icecream Specialist (Gestión de la Barra)

### 📋 Descripción de Avances
Génesis desarrolló los endpoints dedicados a la interfaz del trabajador/especialista detrás de la barra, cerrando el ciclo de vida del pedido:
* **Obtener Cola de Pedidos (`obtener_cola_pedidos.php`):** Extrae en tiempo real los tickets pendientes para que el especialista sepa qué productos debe preparar.
* **Actualizar Estado del Pedido (`actualizar_estado_pedido.php`):** Permite cambiar el estado de la orden (por ejemplo, de `pendiente` o `preparando` a `completado`) al interactuar con la pantalla de la barra.

---

### 🧪 Guía de Pruebas: Cola y Actualización de Pedidos

#### 1. Consulta de la Cola de Pedidos (GET)
Consulta la lista completa de pedidos registrados en el sistema.

* **Método:** `GET`
* **Endpoint:** `http://localhost:8000/obtener_cola_pedidos.php`

##### Ejecución mediante comandos:

* **PowerShell:**
  ```powershell
  Invoke-RestMethod "http://localhost:8000/obtener_cola_pedidos.php"
  ```
* **cURL (Bash):**
  ```bash
  curl -X GET http://localhost:8000/obtener_cola_pedidos.php
  ```

##### Resultado Esperado
Un arreglo JSON con la lista de pedidos en cola y sus detalles (ID, cliente, productos, estado, fecha):

```json
[
  {
    "id_pedido": 1,
    "identificador_cliente": "0951234567",
    "estado": "pendiente",
    "fecha": "2026-08-16 14:30:00",
    "productos": [
      {
        "nombre": "Frappé de Chocolate",
        "cantidad": 2
      }
    ]
  }
]
```

#### 2. Actualización de Estado de un Pedido (POST)
Permite modificar el estado de un pedido específico.

* **Método:** `POST`
* **Endpoint:** `http://localhost:8000/actualizar_estado_pedido.php`
* **Header:** `Content-Type: application/json`

##### Ejecución mediante comandos:

* **PowerShell:**
  ```powershell
  $body = @{
      id_pedido = 1
      estado = "completado"
  } | ConvertTo-Json

  Invoke-RestMethod -Uri "http://localhost:8000/actualizar_estado_pedido.php" -Method Post -Body $body -ContentType "application/json"
  ```

* **cURL (Bash):**
  ```bash
  curl -X POST http://localhost:8000/actualizar_estado_pedido.php     -H "Content-Type: application/json"     -d '{"id_pedido": 1, "estado": "completado"}'
  ```

##### Resultado Esperado
Un JSON indicando la confirmación de la actualización en la base de datos:

```json
{
  "status": "success",
  "message": "Estado actualizado correctamente"
}
```
