## ¿Por qué PostgreSQL y no MySQL?

    Decisión: PostgreSQL será la base de datos transaccional (OLTP) del proyecto.

    Justificación:
    PostgreSQL ofrece un cumplimiento más estricto del estándar SQL, mejor soporte para consultas complejas, funciones analíticas, tipos de datos avanzados y extensibilidad. Estas características lo hacen especialmente adecuado para un proyecto de ingeniería de datos que posteriormente integrará procesos ETL, Apache Spark y un Data Warehouse.

    Alternativas consideradas:

    MySQL: Excelente para aplicaciones web y cargas OLTP, pero con menos funcionalidades analíticas y menor flexibilidad para el tipo de procesamiento que realizaremos.

## ¿Por qué Spark y no Pandas para el procesamiento principal?

    Spark fue diseñdo para el procesamiento distribuido en clústeres, mientras que Pandas procesa datos localmente en una sola maquina dependiendo de su memoria RAM, Spark es superior en estos tres puntos en concreto: 

    Superacion de los limites de memoria
    Evaluación perezosa y Optimizador Catalyst
    Tolerancia a fallos

## ¿Por qué Kafka para el streaming?

    Apache Kafka para streaming permite gestionar millones de eventos en tiempo real con una latencia minima, tambien destaca por su escalabilidad horizontal, alta tolerancia a fallos y su capacidad de persistir eventos en disco y permitir su reprocesamiento de almacenar y retener datos en disco, lo que facilita el procesamiento seguro de la informacion.

## ¿Por qué una arquitectura Medallion?

    Esta arquitectura medallion organiza logicamente los datps en capas incrementales (Bronce, Plata, Oro). Se utiliza para mejorar progresivamente la calidad, estructura y valor del dato, garantizando un flujo estructurado desde la ingesta en bruto hasta el consumo final para analisis