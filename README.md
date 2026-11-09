<div align="center">

# ALU+ CHAMO

### Diseño e implementación física de una ALU síncrona de 16 bits

**SystemVerilog · Verilator / Icarus Verilog · Yosys · OpenROAD · SKY130HD · KLayout**

*Del RTL al layout GDSII mediante un flujo de herramientas abiertas.*

</div>

---

## Descripción del proyecto

**ALU+ CHAMO** es un proyecto de diseño digital y flujo ASIC centrado en una unidad aritmético-lógica síncrona de **16 bits**. El trabajo abarca la descripción del hardware en SystemVerilog, la verificación funcional, la síntesis lógica, la planificación física, la colocación de celdas, la construcción del árbol de reloj, el enrutamiento y la generación del layout final.

El objetivo no es mostrar únicamente el circuito terminado, sino documentar **cómo evoluciona un diseño digital desde su comportamiento lógico hasta una implementación física verificable**.

> **Alcance del flujo:** la implementación aquí documentada se realizó con herramientas *open source* y la biblioteca **SKY130HD**. No se presentan estos resultados como ejecuciones de Synopsys Design Compiler, ICC2 ni como una implementación en GF150/M31.

## Resultados destacados

| Indicador | Resultado |
|:--|--:|
| Ancho de datos | 16 bits |
| Área de celdas tras síntesis ORFS | 17 332,87 µm² |
| Área de celdas al final de la implementación | ≈ 18 798 µm² |
| Período de reloj objetivo | 100 ns (10 MHz) |
| Slack de setup final | +43,74 ns |
| Slack de hold final | +0,35 ns |
| Período mínimo estimado tras routing | 56,26 ns |
| Frecuencia máxima estimada tras routing | 17,77 MHz |
| Violaciones finales de DRC | 0 |
| Comprobación LVS | Netlists coincidentes |

*Las cifras temporales son estimaciones de análisis estático para las condiciones y la esquina evaluadas; no representan una certificación de operación multicorner ni una medición en silicio.*

## 1. Arquitectura digital

El diseño incorpora un módulo de ALU combinacional y una envoltura síncrona con registros y control de validez. Sus bloques RTL incluyen:

- `rtl/alu_plus_sync.sv`: interfaz síncrona y registros de entrada/salida.
- `rtl/alu_plus.sv`: selección y ejecución de operaciones de la ALU.
- `rtl/cla_adder.sv`: sumador de anticipación de acarreo (*carry-lookahead adder*).
- `rtl/restoring_divider.sv`: divisor de tipo *restoring*.
- `rtl/tristate_demo.sv`: demostración RTL independiente de comportamiento triestado.

El módulo `tristate_demo.sv` se conserva como ejemplo didáctico; **no se incluye como parte de la implementación física de `alu_plus_16` documentada aquí**.

El wrapper de implementación física se encuentra en `physical/orfs/alu_plus_16.sv`.

## 2. Verificación funcional

El proyecto cuenta con pruebas funcionales dirigidas y aleatorias. En la regresión de 16 bits realizada previamente se registraron **1 656 comprobaciones satisfactorias**. La captura siguiente muestra específicamente la verificación síncrona de división y módulo.

![Simulación de división y módulo en GTKWave](docs/screenshots/01_simulation/div_mod_waveform.png)

**Figura 1.** Simulación funcional en GTKWave. Con `A = 20` y `B = 3`, el código de control `101` produce `Result = 6` (DIV) y `110` produce `Result = 2` (MOD). `valid_out` indica cuándo cada resultado registrado es válido.

La forma de onda permite observar el reloj, el reinicio, los operandos, la selección de operación, los resultados y las banderas. El período de reloj de esta **simulación funcional** es de 10 ns; no debe confundirse con la frecuencia máxima estimada en el diseño físico.

**Testbenches:** `tb/tb_alu_plus.sv` y `tb/tb_alu_plus_sync.sv`.

## 3. Síntesis lógica

El RTL fue sintetizado y mapeado a celdas estándar de **SKY130HD** dentro de OpenROAD Flow Scripts (ORFS), que utiliza Yosys para la síntesis.

- **Área de celdas sintetizadas:** 17 332,87 µm².
- La implementación física agrega posteriormente celdas y ajustes necesarios para colocación, reloj y cumplimiento de restricciones.
- Los valores de la síntesis ORFS y los de cualquier experimento de síntesis independiente deben identificarse por separado: no necesariamente usan la misma configuración o el mismo mapeo.

## 4. Implementación física

La implementación se realizó mediante el flujo **RTL → síntesis → floorplan/PDN → placement → CTS → routing → GDSII**, con objetivo de reloj de 100 ns.

### 4.1 Floorplan y distribución de alimentación

![Floorplan y red de alimentación](docs/screenshots/03_floorplan/floorplan.png)

**Figura 2.** Vista del diseño al finalizar la etapa de floorplan en ORFS. La captura contiene también las estructuras de alimentación (*PDN*) y las celdas físicas insertadas en esa etapa; por tanto, **no es una imagen del floorplan inicial vacío**.

### 4.2 Placement

![Ubicación de celdas estándar](docs/screenshots/05_placement/placement.png)

**Figura 3.** Distribución de las celdas estándar dentro del núcleo del diseño, tras la colocación física.

### 4.3 Clock Tree Synthesis (CTS)

![Estado físico tras CTS](docs/screenshots/06_cts/cts.png)

**Figura 4.** Estado del diseño después de la síntesis del árbol de reloj. El reporte registra **57 destinos de reloj (*sinks*) y 9 buffers de reloj**. La imagen muestra el estado físico general; **no es una visualización aislada de las ramas del árbol**.

### 4.4 Routing

![Enrutamiento físico](docs/screenshots/07_routing/routing.png)

**Figura 5.** Vista física después del enrutamiento. Se incorporan las conexiones metálicas de las redes de señal. La etapa de enrutamiento detallado terminó con **0 violaciones reportadas por el router**.

### 4.5 GDSII y verificaciones físicas

El diseño final generó un archivo **GDSII**, inspeccionado con KLayout. Se realizaron además dos comprobaciones fundamentales:

- **DRC (Design Rule Check):** 0 violaciones en el reporte final de KLayout.
- **LVS (Layout Versus Schematic):** las netlists coinciden.

Estas comprobaciones validan los resultados de las herramientas y reglas usadas en esta ejecución; no equivalen a una certificación de fabricación de una fundición.

## 5. Análisis de área y temporización

### Evolución del área

![Evolución del área de celdas](docs/charts/area_evolution.png)

**Figura 6.** Evolución del área de celdas estándar durante el flujo. El área pasa de **17 332,87 µm²** tras síntesis a aproximadamente **18 798 µm²** al finalizar la implementación, un aumento cercano al **8,45 %**. Esta magnitud **no es el área total del die**.

### Evolución del timing

![Comparación de frecuencia máxima estimada](docs/charts/timing_evolution.png)

**Figura 7.** Comparación de la frecuencia máxima estimada entre **floorplan (20,41 MHz)** y **post-routing (17,77 MHz)**. **No se trata de una comparación directa de timing de síntesis contra timing de routing**.

| Medición | Floorplan | Post-routing |
|:--|--:|--:|
| Slack de setup | +51,01 ns | +43,74 ns |
| Período mínimo estimado | 48,99 ns | 56,26 ns |
| Frecuencia máxima estimada | 20,41 MHz | 17,77 MHz |

El cambio refleja el avance hacia una representación física más completa, con efectos de reloj y parasitismos de interconexión. No se atribuye toda la variación a una sola causa sin un análisis más detallado de cada contribución.

### Ruta crítica final

- **Origen (setup):** `dut.b_q[0]`.
- **Destino (setup):** `dut.Z` (bandera de cero).
- **Data arrival time:** 56,52 ns.
- **Data required time:** 100,26 ns.
- **Slack de setup:** +43,74 ns.
- **Ruta de hold más exigente:** `dut.valid_q` → `dut.valid_out`, con slack de +0,35 ns.

La ruta de setup atraviesa lógica combinacional entre el registro del operando `B` y el registro de la bandera `Z`. Identificar el registro final permite estudiar el costo temporal de la lógica de banderas además del cálculo del resultado principal.

## 6. Herramientas y metodología

| Área | Herramienta |
|:--|:--|
| Diseño RTL | SystemVerilog |
| Simulación y verificación | Verilator, Icarus Verilog, GTKWave |
| Síntesis | Yosys / ORFS |
| Implementación física y STA | OpenROAD / ORFS |
| Biblioteca de celdas | SKY130HD |
| Inspección del layout | KLayout |
| Automatización y gráficas | Shell, Python, Matplotlib |
| Entorno de ejecución | macOS ARM64 y contenedor Docker `linux/amd64` para ORFS |

## 7. Organización del repositorio

```text
rtl/                    Módulos de diseño en SystemVerilog
tb/                     Testbenches funcionales
physical/orfs/          Wrapper, restricciones y configuración del flujo
docs/charts/            Gráficas y script reproducible
docs/screenshots/       Capturas seleccionadas de simulación y layout
docs/waveforms/         Datos de simulación, cuando se incluyan
```

Los reportes extensos, archivos de trabajo y bases de datos intermedias se conservan como respaldo de ingeniería y no forman parte de la presentación principal del portafolio.

## 8. Conclusiones y próximos pasos

El proyecto demuestra una ejecución completa de un flujo ASIC abierto desde RTL hasta GDSII, con verificación funcional de operaciones aritméticas, análisis temporal y verificaciones físicas finales satisfactorias. La evaluación post-routing identifica como ruta de setup más exigente el camino desde `b_q[0]` hasta la bandera `Z`, lo que proporciona una referencia concreta para futuras optimizaciones.

Como continuidad técnica, sería valioso estudiar una arquitectura de división con diferente partición de etapas, optimizar la ruta de generación de banderas y ejecutar análisis adicionales en múltiples esquinas de proceso, voltaje y temperatura.

---

<div align="center">

**ALU+ CHAMO · Portafolio de diseño digital y flujo ASIC**

</div>
