
** 

\
**UNIVERSIDAD PRIVADA DE TACNA![C:\Users\EPIS\Documents\upt.png](Aspose.Words.9b8249ba-71d9-4a74-a3d4-d5a54232e091.001.png)**

**FACULTAD DE INGENIERÍA**

**Escuela Profesional de Ingeniería de Sistemas**
**\
\


` `**“Proyecto *EvoLearn”***


**Curso:** 

*Patrones de Software*


**Docente:** 

*Mag. Patrick Cuadros Quiroga*\


**Integrantes:**

*Akhtar Oviedo, Ahmed Hasan		-	(2022074261)*

*Anampa Pancca, David Jordan		-	(2022074268)*

*Salas Jimenez, Walter Emmanuel 	-	(2022073896)*

**Tacna – Perú**

*2025*












**Proyecto EvoLearn**

<a name="_heading=h.gjdgxs"></a>**Documento de Visión**

**Versión *1.0***



|CONTROL DE VERSIONES||||||
| :-: | :- | :- | :- | :- | :- |
|Versión|Hecha por|Revisada por|Aprobada por|Fecha|Motivo|
|1\.0|AHAO,  DJAP, WESJ|PCQ|-|17/09/25|Versión 1.0|
<a name="_heading=h.e513eudtg0jr"></a>\
**Índice General**\

======================================
[Índice General	3](#_heading=h.e513eudtg0jr)

[1. Introducción	4](#_heading=h.78rpkyrsbuqf)

[1.1 Propósito	5](#_heading=h.fgbu1opewolx)

[1.3. Referencias	6](#_heading=h.oc0rtkfynj4c)

[1.4. Visión General	6](#_heading=h.vqgsveqhk1rg)

[2. Posicionamiento	8](#_heading=h.v6dep2sxahlx)

[2.1. Oportunidad de negocio	8](#_heading=h.xqxlubnnxyao)

[2.2. Definición del problema	9](#_heading=h.77sflsjx1x0j)

[2.3 Propuesta de valor (MVP: futuro)	10](#_heading=h.krcelpvr2u9o)

[2.4 Indicadores de resultado (para la demo)	11](#_heading=h.slx8o17h80h3)

[3. Descripción de los interesados y usuarios	12](#_heading=h.opp34k5lfvog)

[3.1. Resumen de los interesados	12](#_heading=h.nfk28r5q4shx)

[3.2. Perfiles de los usuarios (MVP)	12](#_heading=h.rysf2pa4apal)

[3.3. Necesidades de interesados y usuarios	13](#_heading=h.6a7nc92d2sys)

[3.4 Matriz RACI (MVP)	13](#_heading=h.xunx3j6walfr)

[4. Vista general del producto	14](#_heading=h.tu8o508xwa6n)

[4.1 Resumen de capacidades	15](#_heading=h.v6b9c8m32l6e)

[4.2 Suposiciones y dependencias (MVP)	15](#_heading=h.36glx9d6cnm)

[4.3 Descripción de costos (orientativa para MVP)	15](#_heading=h.dzjn4jn3we8c)

[4.4 Licenciamiento e instalación	16](#_heading=h.bbuv4nfah5qt)

[4.5 Características del producto (MVP)	16](#_heading=h.vksoupe1vfia)

[4.6 Restricciones (MVP)	16](#_heading=h.bk66jtsgfruh)

[4.7 Criterios/rangos de calidad del MVP	17](#_heading=h.59hs5w389t1w)

[5. Precedencia y prioridad	18](#_heading=h.yvztgkrzhg24)

[6. Lineamientos y estándares del producto	19](#_heading=h.uhlq5loaga9i)

[7. Otros requerimientos del producto	20](#_heading=h.skpde2ix5z6k)

[Conclusiones	21](#_heading=h.uzqa6yhs2vaw)

[Recomendaciones	22](#_heading=h.2jjguxtavxdh)


**Documento de Visión**
1. # <a name="_heading=h.78rpkyrsbuqf"></a>**Introducción**
   El presente documento describe la visión del proyecto EvoLearn, una iniciativa tecnológica orientada a ayudar e incentivar el aprendizaje sobre cualquier tema que el usuario desee. EvoLearn nace como respuesta a una necesidad común en el ámbito académico: la dificultad que enfrentan muchos estudiantes para repasar de manera efectiva el material de estudio, realizar resúmenes concisos y prepararse adecuadamente para exámenes o exposiciones.

   En el ámbito universitario y escolar, miles de estudiantes manejan una gran cantidad de documentos en formato PDF que deben asimilar. La práctica tradicional de resumir y memorizar el contenido puede ser tediosa y poco eficiente. Además, la falta de una herramienta organizada y centralizada para guardar y procesar estos materiales genera limitaciones para un estudio estructurado y una preparación eficaz de los temas.

   EvoLearn busca cerrar esa brecha ofreciendo una aplicación móvil para Android que transforma los documentos estáticos en una experiencia de aprendizaje interactiva y organizada. La aplicación permite al usuario registrarse, gestionar directorios (carpetas) para mantener la información ordenada y subir exclusivamente archivos PDF. La funcionalidad principal reside en su capacidad para analizar el PDF mediante Inteligencia Artificial (IA) y generar automáticamente resúmenes (generales o detallados) en formato .md. Estos resúmenes sirven, a su vez, como base para generar cuestionarios (quizzes) con preguntas importantes sobre el tema, que el usuario puede responder, revisar y reintentar, facilitando un repaso activo. El objetivo es claro: transformar la manera en que los estudiantes abordan el estudio y la preparación, brindando una herramienta que incentive la comprensión profunda y la retención del conocimiento.

   ## <a name="_heading=h.fgbu1opewolx"></a>**1.1 Propósito**
El propósito de este documento es establecer de forma clara los objetivos, alcances y lineamientos del proyecto EvoLearn.

EvoLearn no es solo un gestor de archivos, sino una plataforma de apoyo al estudio y el repaso que permite a los usuarios, a lo que nosotros llamamos, evolución del aprendizaje:

- **Autenticar** su identidad para asegurar la privacidad de sus documentos y progreso.
- **Organizar** su material de estudio mediante la gestión de directorios (carpetas) y la subida exclusiva de archivos PDF.
- **Analizar** PDFs utilizando inteligencia artificial para generar resúmenes automáticos (generales o detallados) en formato .md.
- **Evaluar** su comprensión mediante la generación de cuestionarios (quizzes) basados en el contenido de los resúmenes.
- **Reforzar** el aprendizaje al permitir la revisión de las respuestas del quiz, incluyendo la justificación del porqué de la respuesta correcta.

De esta forma, EvoLearn se convierte en un acompañante del ciclo de estudio, aportando valor a los estudiantes que buscan mejorar su comprensión y preparación para exámenes o exposiciones.

\
**1.2 Alcance**

`	`El alcance del proyecto EvoLearn en su primera fase (MVP) se centra en construir un flujo mínimo funcional que demuestre la organización, el análisis impulsado por IA y la evaluación:

- **Autenticación de Usuarios:** Implementación completa de flujos de **registro** e **inicio de sesión** (cubriendo la necesidad de que el usuario se registre e inicie sesión, **sin incluir funciones administrativas**).
- **Organización:** Interfaz principal con botones para crear directorios y subir archivos, y la visualización de la ruta actual ("raíz").
- **Manipulación de Archivos:** Funcionalidad para subir únicamente archivos PDF.
- **Gestión de Estructura:** Habilidad para mover, eliminar o editar el nombre de directorios y documentos (PDFs y **.md**).
- **Análisis IA:** Opción de "analizar" el PDF, seleccionar tipo de resumen (general/detallado), y guardar automáticamente el resultado como archivo **.md**.
- **Evaluación:** Funcionalidad para generar un quiz basado en el contenido del archivo **.md**, permitir al usuario responderlo, y ofrecer una revisión detallada de las respuestas con su explicación.
- **Repetición del Quiz:** Opción para volver a tomar el quiz sin garantía de que las preguntas sean idénticas.

Lo que quedará fuera del alcance inicial, pero se planificará para fases posteriores, incluye:

- Soporte para formatos de archivo diferentes a PDF.
- Funcionalidad *offline* completa o sincronización avanzada en la nube.
- Estadísticas de rendimiento del estudiante a lo largo del tiempo.
- Compartir documentos o quizzes entre usuarios.
## <a name="_heading=h.oc0rtkfynj4c"></a>**1.3. Referencias**
`	`El proyecto EvoLearn toma como referencia las mejores prácticas de desarrollo de aplicaciones móviles para Android, lineamientos de usabilidad centrados en el estudiante y la aplicación de modelos de lenguaje e inteligencia artificial (IA) para el procesamiento de texto y la generación de contenido educativo. Además, se apoya en:

- Lineamientos de diseño y arquitectura de Google para aplicaciones Android.
- Buenas prácticas de experiencia de usuario (UX) para plataformas de estudio móvil.
- Documentación oficial de los modelos de IA utilizados para garantizar la precisión de los resúmenes y quizzes.
## <a name="_heading=h.vqgsveqhk1rg"></a>**1.4. Visión General**
`	`La visión de EvoLearn es convertirse en la herramienta móvil de referencia para la gestión, el análisis y la evaluación del material de estudio digital entre la comunidad estudiantil de habla hispana, integrando la organización de archivos con capacidades avanzadas de Inteligencia Artificial (IA).

EvoLearn busca ser la plataforma que incentiva el aprendizaje activo y organizado. Para los estudiantes, EvoLearn es una solución práctica que transforma la tediosa tarea de leer PDFs y hacer resúmenes en un proceso estructurado y automatizado, con entregables clave (resúmenes en .md y quizzes generados) que pueden mostrar como evidencia de su progreso. Para aquellos que se les dificulta repasar, es una herramienta didáctica que permite transformar la información densa en conocimiento listo para la evaluación.

En el ámbito del estudio personal, EvoLearn se presenta como un marco adaptable para estudiantes de cualquier nivel que manejan una gran carga de información en formato digital. Al ofrecer un ecosistema modular de gestión de directorios y análisis, los usuarios pueden comenzar organizando su material y escalar hacia el uso constante de los quizzes para el repaso.

La propuesta de valor de EvoLearn se centra en tres ejes principales:

1. **Organización efectiva:** Permite gestionar directorios y subir PDFs, con la habilidad de mover, editar y eliminar tanto documentos como carpetas, facilitando un entorno de estudio ordenado.
1. **Análisis Inteligente:** Transforma PDFs en resúmenes automatizados (generales o detallados) usando IA, lo que ahorra tiempo y enfoca al estudiante en los puntos clave.
1. **Repaso Activo y Medible:** Genera quizzes sobre los resúmenes, permitiendo al usuario responder y revisar sus resultados con justificaciones, incentivando el repaso y la autoevaluación continua.

En definitiva, EvoLearn es una aplicación móvil diseñada específicamente para superar la dificultad de repasar y resumir temas, con un potencial significativo para convertirse en un producto esencial en el mercado de herramientas de tecnología educativa.

1. # <a name="_heading=h.v6dep2sxahlx"></a>**Posicionamiento**

## <a name="_heading=h.xqxlubnnxyao"></a>**2.1. Oportunidad de negocio**
`	`La aplicación móvil EvoLearn surge como una respuesta innovadora a la creciente necesidad de transformar la información de estudio en un formato más accesible, organizado y fácil de repasar. En la actualidad, miles de estudiantes manejan grandes volúmenes de contenido académico en formato PDF, que, aunque está disponible, carece de un proceso estructurado para la asimilación y la autoevaluación. Esta situación representa una oportunidad para aprovechar el valor de ese contenido mediante técnicas de análisis de texto con IA, categorización y generación de herramientas de repaso.

Desde el punto de vista del estudiante, la oportunidad radica en que muchos tienen dificultades para resumir y repasar, lo que se traduce en un bajo rendimiento en exámenes o exposiciones. Una plataforma que organice los documentos en directorios, ofrezca resúmenes generados por IA (generales o detallados) y, crucialmente, permita generar quizzes sobre el tema, facilitará la detección de áreas de mejora y la planificación de estrategias de estudio efectivas.

Por su parte, en el ámbito de la Tecnología Educativa (EdTech), la oportunidad consiste en disponer de un sistema que integre la gestión de archivos con capacidades de Inteligencia Artificial para el aprendizaje, lo cual abre la posibilidad de fidelizar a los usuarios ofreciendo un valor añadido significativo que va más allá del simple almacenamiento de documentos.

En suma, el proyecto no solo responde a una necesidad tecnológica (organización de archivos en Android), sino que aborda una necesidad educativa y social, consolidándose como una herramienta de valor en la mejora de la eficiencia en el estudio.
## <a name="_heading=h.77sflsjx1x0j"></a>**2.2. Definición del problema**
En la actualidad, los estudiantes enfrentan una problemática constante: la dificultad para repasar o realizar resúmenes de manera eficiente, lo que afecta su comprensión de los temas. La metodología de estudio tradicional requiere que los alumnos inviertan grandes cantidades de tiempo y esfuerzo en leer extensos PDFs, identificar las ideas principales y redactar resúmenes a mano o digitalmente. Estas tareas, que deberían ser herramientas de apoyo, se convierten en obstáculos que generan retrasos, inconsistencias y una baja motivación para el repaso.

Para los estudiantes universitarios y aquellos que se preparan para exámenes, esta situación se traduce en experiencias de aprendizaje incompletas. Aunque tienen acceso a la información (los PDFs), en la práctica, muchos solo alcanzan a leer fragmentos sin comprender la estructura integral del tema. De este modo, el material de estudio se queda como contenido inaccesible sin una conexión real con la necesidad de evaluación.

En el caso de estudiantes con una alta carga académica, el problema se refleja en tiempos prolongados de preparación y baja retención. Gestionar la organización de múltiples documentos en diferentes asignaturas y tener que generar resúmenes constantemente son tareas que consumen semanas antes de poder enfocarse en el aprendizaje profundo. Además, la ausencia de una herramienta de autoevaluación estandarizada dificulta medir su progreso y aumenta el riesgo de llegar a un examen sin la preparación adecuada.

La falta de un sistema integral que organice el material de estudio y automatice el resumen y el repaso convierte el proceso de preparación en una actividad ineficiente y desordenada. En consecuencia, los estudiantes no alcanzan el nivel de comprensión esperado y enfrentan estrés, sobrecarga y una pérdida de competitividad académica.
## <a name="_heading=h.krcelpvr2u9o"></a>**2.3 Propuesta de valor** 
La propuesta de valor central de EvoLearn se enfoca en resolver el problema crítico que enfrentan los estudiantes: la dificultad para organizar, resumir y repasar grandes volúmenes de material de estudio digital (PDFs). EvoLearn transforma la experiencia de estudio de ser pasiva y manual a ser activa, organizada y automatizada mediante el uso de la Inteligencia Artificial. La aplicación ofrece una solución integral que va más allá del simple almacenamiento de archivos.

El valor de EvoLearn radica en tres pilares clave. En primer lugar, ofrece una Organización Estructurada al permitir a los usuarios subir exclusivamente archivos PDF y gestionarlos mediante un sistema de directorios flexible, donde tanto carpetas como documentos pueden ser movidos, renombrados o eliminados. Esto brinda a los estudiantes un entorno de estudio ordenado y centralizado.

En segundo lugar, el componente de Análisis Inteligente por IA es fundamental. Al seleccionar la opción "analizar", EvoLearn utiliza IA para procesar el PDF y generar automáticamente resúmenes (generales o detallados) que se guardan instantáneamente en formato Markdown (.md). Esta funcionalidad ahorra incontables horas de lectura y redacción, permitiendo al estudiante enfocarse en el contenido ya sintetizado.

Finalmente, el valor se consolida con la Evaluación Activa y el Refuerzo. Los archivos de resumen (.md) tienen la capacidad de generar un quiz interactivo con preguntas importantes. El estudiante puede responder, revisar sus respuestas con una explicación detallada ("el porqué") y volver a tomar el quiz. Este ciclo de autoevaluación garantiza que el repaso sea efectivo, refuerce el aprendizaje y prepare mejor al usuario para exámenes o exposiciones. En esencia, EvoLearn es la herramienta móvil que convierte los archivos PDF estáticos en una dinámica y poderosa plataforma de estudio personalizado.
## <a name="_heading=h.slx8o17h80h3"></a>**2.4 Indicadores de resultado (para la demo)**
El éxito del proyecto EvoLearn se medirá a través de indicadores concretos que reflejen su impacto en la eficiencia y organización del estudio. En términos de rapidez de procesamiento, se buscará que un usuario pueda subir un PDF, analizarlo con IA y generar el primer archivo de resumen (.md) en menos de un minuto para documentos de longitud estándar. En cuanto a usabilidad, el objetivo será alcanzar un nivel de satisfacción superior al ochenta y cinco por ciento en pruebas piloto con estudiantes, evaluando la claridad de la interfaz, la facilidad de uso del sistema de directorios y la intuición en el ciclo de quiz (respuesta y revisión).

La fiabilidad de la IA constituirá otro indicador clave, medida por la tasa de éxito en la generación de contenido (resúmenes y quizzes), siendo necesario que el 95% de los intentos de análisis y generación de quiz sean completados exitosamente en la primera versión para demostrar la cadena mínima de valor. En efectividad del repaso, se evaluará que el usuario utilice la función de revisión de respuestas con explicación al menos una vez por cada quiz tomado. Desde la perspectiva de adopción, se considerará un éxito la cantidad de estudiantes que adopten EvoLearn como su herramienta principal para la organización de PDFs y el repaso. Finalmente, el impacto se medirá a partir de la frecuencia de uso de la función de quiz, cuantificando la mejora percibida por los usuarios en la retención y la comprensión del material de estudio.

**Principales indicadores del éxito de EvoLearn:**

- **Rapidez de Procesamiento:** Subir PDF y generar resumen (.md) en menos de 1 minuto.
- **Usabilidad:** Satisfacción superior al 85% en pruebas piloto con estudiantes.
- **Fiabilidad de Contenido IA:** Éxito igual o mayor al 95% en la generación de resúmenes y quizzes.
- **Efectividad del Repaso:** Uso de la función de revisión y explicación en el 100% de los quizzes terminados.
- **Adopción:** Número de estudiantes que adoptan EvoLearn como herramienta de estudio y repaso.
- **Impacto Académico:** Mejora percibida en la comprensión, retención y reducción del tiempo de preparación.
# <a name="_heading=h.opp34k5lfvog"></a>**3. Descripción de los interesados y usuarios**
## <a name="_heading=h.nfk28r5q4shx"></a>**3.1. Resumen de los interesados**
Los interesados en **EvoLearn** se centran en el ecosistema educativo, principalmente aquellos que buscan herramientas para mejorar su rendimiento académico:

- **Estudiantes (Usuarios Finales):** Buscan activamente una solución práctica para la **gestión organizada de archivos PDF**, la **generación automática de resúmenes** y un método de **autoevaluación activa (quizzes)** para prepararse eficazmente para exámenes o exposiciones. Son el grupo objetivo principal, incluyendo estudiantes universitarios, escolares o de formación continua que tienen dificultades para repasar.
- **Desarrolladores y Propietarios del Proyecto:** Interesados en el desarrollo, estabilidad, usabilidad y **adopción masiva** de EvoLearn como un producto competitivo en el mercado de tecnología educativa (EdTech) para Android.
## <a name="_heading=h.rysf2pa4apal"></a>**3.2. Perfiles de los usuarios (MVP)**
Dentro del conjunto de interesados, se define un perfil de usuario principal que interactúa directamente con el sistema y determina los requerimientos de diseño y funcionalidad:

- **Usuario Estudiante/Estudioso:** Desea **organizar eficientemente** su material de estudio, necesita **resúmenes rápidos** y busca métodos de **autoevaluación activa (quizzes)** para reforzar su aprendizaje y prepararse para exámenes. Es el usuario principal de la aplicación móvil.
## <a name="_heading=h.6a7nc92d2sys"></a>**3.3. Necesidades de interesados y usuarios**
|**Parte interesada / Usuario**|**Necesidad clave (MVP)**|**Cómo lo cubre el MVP**|
| - | - | - |
|Estudiante/Estudioso|Organizar material de estudio (PDFs).|Sistema de directorios flexible (crear, mover, editar, eliminar directorios y PDFs).|
|Estudiante/Estudioso|Generar resúmenes de forma rápida.|Opción "analizar" PDF con IA para crear resúmenes automáticos (.md) (general/detallado).|
|Estudiante/Estudioso|Autoevaluarse y repasar.|Generación de Quizzes a partir del resumen (.md), con opción de respuesta y revisión con "el porqué".|
|Estudiante/Estudioso|Acceso seguro a su información.|Flujos de autenticación completos (registro e inicio de sesión).|
|Propietarios/Desarrolladores|Validar la propuesta de valor.|Tasa de éxito y fiabilidad de la generación de resúmenes y quizzes con IA.|


## <a name="_heading=h.jibgiy54iyqh"></a>**
## <a name="_heading=h.xunx3j6walfr"></a>**3.4 Matriz RACI (MVP)**
La matriz RACI define las responsabilidades clave para el desarrollo y validación del Producto Mínimo Viable de EvoLearn. Dado que solo hay un rol de Usuario Final y los roles internos del proyecto son genéricos, se adapta la tabla:

**R =** Responsable (ejecuta), **A =** Aprobador (decide)**,  C =** Consultado**, I =** Informado
|**Actividad**|**Usuario Final**|**Equipo Desarrollo**|**Diseñador UX/UI**|**Propietario Producto**|
| :-: | :-: | :-: | :-: | :-: |
|Definir criterios de aceptación de la IA (Resúmenes/Quizzes)|C|R|I|A|
|Diseño funcional de la interfaz móvil (Android)|C|C|R|A|
|Desarrollo de la autenticación y gestión de directorios|I|R|C|A|
|Pruebas de usabilidad y funcionalidad del quiz|R|C|R|A|
|Retroalimentación y solicitud de mejoras (MVP)|A|C|C|R|

# <a name="_heading=h.tu8o508xwa6n"></a>**4. Vista general del producto**
`	`EvoLearn, en su primera fase (MVP), se concreta como una aplicación móvil para Android que integra la organización de documentos con capacidades de Inteligencia Artificial para el apoyo al estudio.

El producto inicial no pretende reemplazar las herramientas de almacenamiento en la nube, sino integrar la gestión de archivos PDF en un flujo ordenado y automatizado de aprendizaje. Demuestra cómo se conectan la subida de un documento, la organización en directorios, la generación del resumen por IA y la creación de un quiz para la autoevaluación, todo dentro de una misma plataforma.

El objetivo es que los usuarios puedan transformar sus archivos PDF en conocimiento listo para el repaso y la evaluación en menor tiempo y con menos fricción, logrando resultados tangibles que se adapten a la necesidad de repasar temas y estudiar para exámenes o exposiciones.
##
## <a name="_heading=h.l4jmxtf6yi0g"></a><a name="_heading=h.v6b9c8m32l6e"></a>**4.1 Resumen de capacidades**
**Incluido en el MVP (esta entrega):**

- **Gestión de la Estructura de Contenido:** Flujo completo de autenticación (registro/inicio de sesión), creación/visualización de directorios, y subida/gestión de archivos (mover, editar, eliminar PDF y **.md)**.
- **Análisis de Contenido IA:** Funcionalidad para **analizar PDFs** y generar **resúmenes** (generales o detallados) que se guardan en formato **.md**.
- **Evaluación Activa:** Capacidad de generar y tomar un **quiz** a partir del resumen, con **revisión de respuestas y justificación** ("el porqué").
- **Interfaz Amigable y Clara:** Diseño móvil intuitivo para estudiantes, centrado en la usabilidad y la facilidad de navegación en la estructura de directorios.
- **Sistema de Notificaciones:** Mensajes claros para informar sobre errores (ej. intento de subir un formato diferente a PDF) y estados de procesos (ej. "Resumen generado exitosamente").

**Planeado para fases futuras (no incluido en el MVP):**

- Compatibilidad con otros formatos de archivo además de PDF.
- Funcionalidad *offline* para la lectura de resúmenes y toma de quizzes.
- Integración con la nube para copias de seguridad avanzadas.
- Estadísticas de progreso y métricas de retención para el estudiante.
## <a name="_heading=h.36glx9d6cnm"></a>**4.2 Suposiciones y dependencias (MVP)**
`	`El desarrollo del Producto Mínimo Viable (MVP) de EvoLearn se basa en las siguientes condiciones y dependencias:	

- **Dependencia de Conexión a Internet Estable:** La funcionalidad de **análisis por IA** y la **generación de quizzes** requieren una conexión activa y estable para interactuar con los modelos de lenguaje.
- **Uso de Dispositivos Android Modernos:** La aplicación será desarrollada para ser compatible con una gama razonable de dispositivos móviles con versiones recientes del sistema operativo **Android**.
- **Stack Técnico Inicial Definido:** El desarrollo se realizará sobre un *stack* tecnológico que podría incluir, por ejemplo, **Kotlin/Java/Flutter/React Native** para el *frontend* móvil, y un *backend* (si aplica) con tecnologías adecuadas para procesar archivos y ejecutar la IA.
- **Seguridad Básica de Autenticación:** Se implementarán mecanismos estándar para el registro e inicio de sesión, pero sin incluir características de seguridad avanzadas o autenticación multifactor en esta primera fase.
## <a name="_heading=h.dzjn4jn3we8c"></a>**4.3 Descripción de costos (orientativa para MVP)**
- **Costos generales:** Documentación de la aplicación (Manual de usuario, guías rápidas), materiales de testing y prototipado.
- **Costos operativos:** Consumo de la API/modelo de IA utilizado para la generación de resúmenes (si tiene un costo por llamada) durante las pruebas piloto; consumo eléctrico y hosting básico de desarrollo (si aplica un backend).
- **Costos de personal:** Personal	Dedicación del equipo de desarrollo (estudiantes) estimada en aproximadamente un mes, con un enfoque intensivo de ~2 semanas efectivas para la codificación y pruebas de las funcionalidades principales (autenticación, gestión de directorios, análisis IA, y quiz).
- **Total (estimativo):** Suma de los rubros anteriores, centrados en el uso de recursos tecnológicos (IA) y el tiempo del equipo. (En la versión final, se detallarán las horas hombre y los costos de las APIs de IA).

|<p></p><p>*Concepto*</p>|<p></p><p>*Costo*</p>|
| - | - |
|Costos generales|S/. 60.00|
|Costos operativos|S/. 92.00|
|Costos de personal|S/. 4229.90|
|Total|S/. 4381.00|

## <a name="_heading=h.bbuv4nfah5qt"></a>**4.4 Licenciamiento e instalación**
El proyecto **EvoLearn** se desarrollará bajo un modelo de **uso académico y demostrativo** durante la fase inicial del MVP, por lo que **no es comercial** en esta etapa. Se establecerá un licenciamiento abierto para fines exclusivamente educativos e investigativos que permita a otros estudiantes analizar y aprender de su estructura. El despliegue inicial se realizará como una **aplicación móvil Android**, requiriendo que los usuarios descarguen e instalen el archivo de paquete (APK) o utilicen un entorno de prueba de Android.
## <a name="_heading=h.vksoupe1vfia"></a>**4.5 Características del producto (MVP)**
- **Interfaz Clara y Funcional:** Navegación intuitiva centrada en la estructura de directorios (carpetas), permitiendo un flujo lógico: Subida de PDF $\rightarrow$ Análisis IA $\rightarrow$ Resumen .md $\rightarrow$ Generación de Quiz.
- **Diseño Visual Consistente:** Uso de una paleta de colores corporativos y componentes de diseño Android estándar, asegurando una experiencia de usuario responsiva y adaptada a diferentes tamaños de pantalla móvil.
- **Contenido Entendible:** Mensajes de estado y error redactados de forma clara y accesible para el usuario, sin jerga técnica (ej. "Error al conectar con la IA, por favor verifica tu conexión").
- **Soporte Básico:** Se proveerá un manual de usuario simple (en formato digital) con los pasos básicos para la autenticación, la gestión de directorios y el uso de la función de análisis y quiz.
- **Optimización Ligera:** La aplicación será desarrollada para ser funcional y fluida en dispositivos móviles Android de gama media.
- **Seguridad Inicial:** Implementación de un flujo de inicio de sesión y registro básico (Autenticación), protegiendo el acceso a los documentos y directorios de cada usuario de forma individual.
## <a name="_heading=h.bk66jtsgfruh"></a>**4.6 Restricciones (MVP)**
- **Sin Analíticas Avanzadas:** La aplicación no incluirá dashboards de progreso, reportes dinámicos ni inteligencia de negocio (BI) sobre el rendimiento del estudiante en la primera versión.
- **Dependencia Total de Conexión a Internet:** La **función de análisis de PDF y generación de quiz con IA requiere de conexión constante** para comunicarse con el modelo de lenguaje.
- **Autenticación Estándar:** El proceso de *login* será básico (basado en credenciales), **sin integración institucional** o *single sign-on*.
- **Sin Sincronización Avanzada:** La aplicación será monousuario en el MVP; no incluirá funciones para compartir archivos o colaborar.
- **Escalabilidad Limitada de Archivos:** La capacidad de procesamiento de la IA para resúmenes podría estar limitada a PDFs de una extensión mediana o pequeña, con un enfoque en el procesamiento rápido de documentos de estudio (<100 páginas en esta fase inicial).
## <a name="_heading=h.59hs5w389t1w"></a>**4.7 Criterios/rangos de calidad del MVP**
Para garantizar la validez del MVP, se establecerán criterios de calidad que permitan medir su desempeño en las fases iniciales de uso.

En cuanto a Experiencia de Usuario, se buscará alcanzar una satisfacción mínima del ochenta por ciento (80%) en pruebas piloto, asegurando además que los mensajes de estado, error y las justificaciones del quiz sean claros y sin ambigüedades.

En términos de Desempeño, el sistema deberá responder en menos de tres segundos (3s) al iniciar el proceso de análisis de un PDF, y se espera que al menos el noventa por ciento (90%) de los resúmenes y quizzes generados sean contextualmente correctos y se almacenen apropiadamente.

Respecto a Confiabilidad, se establece como meta una tasa de fallos críticos igual a cero (0) durante las demostraciones de las funciones de IA, con mecanismos de recuperación guiada (mensajes de error claros) ante fallos de conexión a Internet o intentos de subir archivos no soportados.

Finalmente, en materia de Seguridad y Privacidad, el MVP no almacenará datos sensibles (solo credenciales de autenticación y los archivos de estudio del usuario), restringiendo el acceso únicamente a los usuarios autenticados, lo que asegura un entorno controlado para el material de estudio.

**Puntos clave:**

- **Experiencia de Usuario:** $\geq 80\%$ de satisfacción y mensajes claros.
- **Desempeño:** Tiempo de respuesta $< 3$ segundos en el inicio del análisis y generación de contenido $\geq 90\%$ correcta.
- **Confiabilidad:** Tasa de fallos críticos $= 0$ en la demo y recuperación guiada ante fallos menores.
- **Seguridad:** Sin almacenamiento de datos sensibles y acceso restringido solo al usuario autenticado.
# <a name="_heading=h.yvztgkrzhg24"></a>**5. Precedencia y prioridad**
La estrategia de EvoLearn establece prioridades claras para asegurar una implementación incremental exitosa. En primer lugar, se dará prioridad absoluta a las funciones de Autenticación (registro/login) y la Gestión de Directorios y Archivos PDF, ya que estas constituyen la base para la organización del material de estudio. Posteriormente, se añadirá la fase de Análisis por IA para la generación de resúmenes, seguida de la incorporación de la función de Generación y Toma de Quizzes que aseguran la capacidad de autoevaluación desde etapas tempranas.

Una vez asegurada la funcionalidad de estudio, se integrará el sistema de revisión del quiz con explicación ("el porqué"), que permitirá a los usuarios obtener el máximo valor pedagógico del sistema. Finalmente, se incorporará el pulido de la interfaz y la optimización de los mensajes de estado y error. Esta progresión garantiza que los usuarios experimenten resultados tangibles en cada fase de desarrollo, validando la propuesta de valor y asegurando un aprendizaje incremental.

**Priorización:**

- **P0 (Imprescindible):** Autenticación (registro/login), gestión de directorios, subida de PDFs y funcionalidad completa de **Análisis IA** para generar resúmenes (.md).
- **P1 (Fluidez):** Generación y toma del quiz, revisión de respuestas con justificación y operaciones de gestión de archivos (mover, editar, eliminar) rápidas.
- **P2 (Usabilidad):** Diseño visual consistente, manual breve de uso y mensajes claros de estado y error.
- **P3 (Pulido):** Optimización del rendimiento móvil y refinamiento de la experiencia de usuario (UX) en la revisión del quiz.

**Criterios de aceptación (demo):**

- Login y cierre de sesión totalmente operativos.
- Ejecución de tareas básicas (crear directorio, subir PDF, generar resumen, tomar quiz) con $\geq 95\%$ de precisión en pruebas.
- Tiempo de respuesta $< 3$ segundos en el inicio del proceso de análisis del PDF.
- Almacenamiento de resúmenes (.md) y resultados del quiz sin errores ni pérdida de información.
- Mensajes claros en casos de acceso inválido, intento de subir archivos no soportados o error de conexión.
- Sin pérdida de archivos o fallos en operaciones críticas del flujo de trabajo (gestión de directorios y documentos).
# <a name="_heading=h.uhlq5loaga9i"></a>**6. Lineamientos y estándares del producto**
El sistema EvoLearn se fundamenta en lineamientos de seguridad, accesibilidad y calidad que aseguran la confiabilidad de la información procesada y presentada al estudiante.

**Legales y normativos:**

- **Cumplimiento de la Ley de Protección de Datos Personales:** Solo se almacenan los datos mínimos necesarios para la autenticación y la información de estudio subida por el usuario (PDFs y resúmenes). **No se almacenan datos personales sensibles**.
- **Seguridad y Privacidad:** Se incluyen validaciones de integridad para evitar la manipulación indebida de los archivos de resumen y accesos no autorizados a la información de otros usuarios.

**Accesibilidad y usabilidad:**

- Interfaz con contraste legible, tipografía clara y menús navegables, enfocados en un entorno de **aplicación móvil Android**.
- Flujo intuitivo: **Login** $\rightarrow$ **Gestión de Directorios** $\rightarrow$ **Análisis de PDF** $\rightarrow$ **Generación/Toma de Quiz**.

**Seguridad en el sistema:**

- Control de acceso por login con encriptación de contraseñas.
- Sesiones con cierre automático tras inactividad prolongada (si aplica al diseño móvil).
- Logs técnicos para depuración, sin almacenar el contenido de los resúmenes o PDFs en los registros de errores.

**Calidad y mejora continua:**

- Evidencia de pruebas funcionales (gestión de archivos, generación de resúmenes y funcionamiento del quiz).
- Control de versiones del código fuente del sistema.
- Pruebas de rendimiento (tiempo de respuesta) y estabilidad (sin fallas críticas en demo).
# <a name="_heading=h.tucjlkbk7v28"></a>**
# <a name="_heading=h.skpde2ix5z6k"></a>**7. Otros requerimientos del producto**
Para garantizar su operatividad, EvoLearn requiere acceso a internet estable (esencial para la IA) y ser ejecutado en dispositivos Android compatibles. Cada función clave estará acompañada de documentación técnica y guías breves, lo que asegura su fácil adopción y uso. La plataforma ha sido diseñada con una arquitectura modular, de modo que las funcionalidades básicas del MVP puedan evolucionar para soportar otras características avanzadas.

**Esenciales del MVP:**

- **Compatibilidad:** Aplicación funcional en dispositivos Android de gama media o superior.
- **Instalación:** Despliegue mediante la descarga e instalación del archivo APK en el dispositivo Android.
- **Soporte:** Manual breve para el usuario sobre el ciclo de estudio (subida, análisis, quiz) y resolución de errores comunes.
- **Almacenamiento:** Uso de una base de datos o almacenamiento en la nube adecuado para gestionar las credenciales de usuario y el árbol de directorios/archivos.
- **Limitaciones iniciales:** Sin notificaciones automáticas (ej. quiz recordatorios), sin sincronización avanzada en tiempo real, y sin módulos predictivos o de analíticas de rendimiento.
# <a name="_heading=h.qz7sn1cdmcge"></a>**Conclusiones**
EvoLearn representa una propuesta innovadora y esencial en el ámbito de las herramientas de tecnología educativa (EdTech). Al integrar de forma organizada la gestión de documentos, el análisis de IA para resúmenes y la autoevaluación activa mediante quizzes, se posiciona como una herramienta única que atiende la necesidad de los estudiantes que tienen dificultades para repasar y comprender temas complejos. En el plano educativo, se convierte en un aliado estratégico para cualquier estudiante que busque transformar archivos PDF pasivos en material de estudio dinámico y evaluable. Para el usuario, constituye una oportunidad de aprender de manera más eficiente, con entregables reales (resúmenes y resultados de quiz) que fortalecen sus competencias de comprensión y retención.

En el plano del estudio personal, EvoLearn responde a los desafíos de la desorganización y la sobrecarga de información, permitiendo a los usuarios ahorrar tiempo en la redacción de resúmenes y garantizar la calidad del repaso. Su enfoque incremental permite obtener resultados tangibles desde el primer uso, validando ideas y acelerando el ciclo de estudio. Con un MVP que recorre desde la subida del PDF hasta la revisión del quiz, EvoLearn demuestra que es posible transformar la forma en que se aborda el material de estudio.

En definitiva, EvoLearn no es solo un proyecto académico, sino una herramienta con proyección real en el mercado. Su capacidad para conectar el material de lectura con el proceso de evaluación lo convierte en un marco integral que puede escalar desde el aula hasta la preparación de oposiciones o certificaciones profesionales, consolidándose como un referente en la optimización del estudio a través de la tecnología móvil.

# <a name="_heading=h.2jjguxtavxdh"></a>**Recomendaciones**
- # <a name="_heading=h.3yib7bbu56xp"></a>**Validar primero la Precisión de la IA en Resúmenes y Quizzes:**
  Antes de enfocarse en la adopción masiva, se recomienda realizar pruebas exhaustivas con una amplia variedad de PDFs temáticos (ciencias, humanidades, etc.). Esto permitirá obtener *feedback* estructurado sobre la calidad y relevancia de los resúmenes y las preguntas generadas por la IA, corrigiendo errores con menor riesgo.

- **Construir el MVP con un Enfoque en la Cadena de Valor del Estudio:**

  EvoLearn tiene muchas funcionalidades (gestión de archivos, IA, quizzes). Para evitar sobrecarga, se sugiere priorizar y liberar el sistema por fases, empezando con la **Autenticación y Gestión de Archivos (P0)**, luego el **Análisis y Resumen IA (P0)**, y finalmente el **Quiz y Revisión (P1)**. Esto mostrará resultados rápidos y medibles.

- **Enfocarse en la Experiencia de Usuario (UX) de la Evaluación:**

  Como EvoLearn busca incentivar el aprendizaje, se recomienda invertir esfuerzo especial en la claridad de la interfaz del quiz, los mensajes de **"el porqué"** de las respuestas correctas y la facilidad para reintentar. Una mala experiencia en esta etapa clave podría reducir la adopción temprana.

- **Definir Métricas de Impacto en la Eficiencia del Estudio:**

  No solo basta con que el sistema funcione; debe demostrar valor académico. Se recomienda medir:

  - **Tasa de éxito** en la generación de resúmenes y quizzes.
  - **Reducción de tiempo** que el usuario invierte en tareas de resumen manual.
  - **Frecuencia de uso** de la función de quiz (indicador de repaso activo).
- **Planificar la Sostenibilidad y Evolución del Producto:**

  Para que EvoLearn no se quede en un prototipo, es clave trazar una ruta clara de escalamiento: soporte para otros formatos de archivo, funciones *offline*, y posible integración con servicios en la nube para copias de seguridad. Esto permitirá que pase de un producto académico a una herramienta de estudio indispensable.



