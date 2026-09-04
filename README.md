# 🍕 Gestor de Pizzería Full-Stack

Aplicación móvil nativa desarrollada para optimizar el flujo de trabajo de un emprendimiento pizzero independiente. El sistema permite la gestión integral de un menú dinámico, la administración de comandas en tiempo real y la sincronización de estados entre el carrito de compras del cliente y el panel de cocina.

## 🚀 Tecnologías y Arquitectura

### Frontend (Móvil)
*   **Framework:** Flutter / Dart
*   **Manejo de Estado:** Provider (Gestión reactiva de la memoria del carrito y cálculo de totales).
*   **Navegación:** Enrutamiento nativo con `Navigator` y adaptación de UI con `SafeArea`.
*   **Consumo de Datos:** Implementación de `FutureBuilder` para catálogos asíncronos y `StreamBuilder` para websockets.

### Backend (Base de Datos como Servicio)
*   **Plataforma:** Supabase
*   **Base de Datos:** PostgreSQL (Tablas relacionales `productos` y `comandas`).
*   **Estructura de Datos:** Almacenamiento de pedidos estructurados en formato `JSONB`.
*   **Seguridad (RLS):** Row Level Security configurado para permitir lectura de menú e inserción/actualización de comandas mediante llaves anónimas.
*   **Realtime:** Publicaciones SQL activadas para reflejar instantáneamente el ingreso de pedidos en el panel de administrador sin recargar la app.

## ⚙️ Funcionalidades Principales
1.  **Catálogo Dinámico:** El menú, los ingredientes y los precios se renderizan consultando la tabla `productos` en la nube, permitiendo ajustes de precios o stock sin necesidad de recompilar la aplicación.
2.  **Gestión de Carrito:** Almacenamiento temporal en memoria global mediante Provider. Suma de montos dinámicos e inyección de datos agrupados al backend al confirmar.
3.  **Panel de Cocina en Vivo:** Interfaz de administrador que "escucha" la tabla `comandas`. Los pedidos nuevos aparecen automáticamente, y el sistema permite cambiar el estado del pedido (de `pendiente` a `listo`) impactando directamente en la base de datos relacional.

## 🔮 Próximos Pasos (Integración IoT)
La siguiente fase del proyecto escalará el software hacia el control de hardware físico. Utilizando microcontroladores (ESP32/ESP8266) programados en C++, el sistema leerá los cambios de estado en Supabase para activar interrupciones de hardware y módulos de relés, disparando alarmas físicas e indicadores lumínicos en el local cuando ingrese un nuevo pedido.
