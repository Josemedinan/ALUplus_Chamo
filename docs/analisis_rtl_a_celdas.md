# Transformación del RTL a hardware — ALU+ CHAMO

Este documento explica cómo se describe la ALU+ en SystemVerilog y cómo se interpreta su implementación sobre celdas estándar **SKY130HD**. Las observaciones de RTL se basan en los módulos del repositorio. Las cifras de área/timing proceden del flujo OpenROAD documentado; la distribución exacta de celdas por submódulo requiere un análisis jerárquico adicional.

## 1. Jerarquía y parametrización

- `alu_plus.sv`: ALU combinacional, parámetro `WIDTH = 8`.
- `cla_adder.sv`: sumador CLA, parámetro `WIDTH = 8`.
- `restoring_divider.sv`: divisor restoring sin signo, parámetro `WIDTH = 8`.
- `alu_plus_sync.sv`: captura operandos/control/validez en registros y registra las salidas, parámetro `WIDTH = 8`.
- `physical/orfs/alu_plus_16.sv`: wrapper **fijo a 16 bits** que instancia `alu_plus_sync #(.WIDTH(16))`. La parametrización está en el núcleo; el wrapper físico corresponde específicamente a esta corrida.

El flujo combina registros de entrada, lógica combinacional y registros de salida. Entre el muestreo de entradas y la salida válida hay dos flancos positivos de reloj.

## 2. Selección de operación y multiplexores

La ALU usa `ALUControl[2:0]`: `000` AND, `001` OR, `010` ADD, `011` SLT con signo, `100` reservado/cero, `101` DIV sin signo, `110` MOD sin signo y `111` cero. La estructura `case` asigna `Result` y constituye lógica de selección sintetizable: el mapeador puede representarla mediante multiplexores y compuertas combinacionales de la biblioteca. No se supone una correspondencia de una celda por instrucción RTL.

## 3. CLA (*carry look-ahead adder*)

`cla_adder.sv` calcula `p = a ^ b` (propagación) y `g = a & b` (generación). Dentro de cada grupo de hasta cuatro bits desarrolla expresiones de acarreo *look-ahead*, combinando términos de generación y productos de propagación. El número de grupos es `(WIDTH + 3) / 4`, por lo que admite anchuras que no son múltiplos de cuatro.

En la síntesis, las ecuaciones booleanas pueden convertirse a XOR/XNOR, AND, OR y celdas combinadas AOI/OAI. **El código no contiene un prefijo paralelo global**; el acarreo entre grupos continúa a través de `group_c`. La latencia depende de la estructura resultante y de la optimización, no únicamente del nombre «CLA».

Para `SLT`, el sumador calcula `A + ~B + 1`, y el bit de comparación con signo se corrige por overflow.

## 4. Divisor restoring

`restoring_divider.sv` implementa división entera **sin signo**. En cada una de `WIDTH` iteraciones desplaza el residuo parcial, compara con el divisor y, si corresponde, resta y fija el bit del cociente. La descripción es un bloque combinacional, no un divisor secuencial de `WIDTH` ciclos.

Al sintetizar, el bucle estático se expande a lógica combinacional de comparación, resta y selección. Esta red puede ser relativamente profunda y consumir área; identificarla como responsable exacta de la ruta crítica requiere inspeccionar la trayectoria completa.

La convención usada para divisor cero es: cociente con todos los bits en uno, residuo igual al dividendo y bandera `div_by_zero` activa para DIV/MOD. No representa una división matemática válida.

## 5. AND/OR: triestado frente a aislamiento

La especificación académica pide desconectar mediante triestado las operaciones AND y OR cuando no están seleccionadas.

`tristate_demo.sv` ilustra el comportamiento de alta impedancia en simulación de cuatro estados:
`assign and_bus = enable_and ? (A & B) : {WIDTH{1'bz}};`.

**Sin embargo, este módulo no figura entre los archivos RTL de la síntesis ORFS de `alu_plus_16`.** La ALU física usa aislamiento de operandos: `do_and ? A : '0` y equivalentes para B/OR. Esto puede evitar propagación de cambios lógicos a las compuertas de operación no seleccionadas, pero **no crea un bus interno eléctricamente triestado** ni garantiza una reducción de potencia sin medición. La transformación consiste en multiplexores/compuertas de control y puertas AND/OR ordinarias; no puede afirmarse que haya buffers triestado en el GDSII.

Esta decisión es una alternativa de implementación en celdas estándar, **no cumplimiento literal del requisito de triestado físico**.

## 6. Registros, banderas y temporización

`alu_plus_sync.sv` registra `A`, `B`, control y validez, y registra `Result`, `N`, `Z`, `C`, `V` y `div_by_zero`. El reset es activo en bajo y asíncrono.

- `N`: bit más significativo de `Result`.
- `Z`: comparación `Result == 0`.
- `C` y `V`: definidos para ADD y SLT; los demás códigos producen cero.
- `div_by_zero`: bandera aplicable a DIV/MOD.

En el reporte STA final, la trayectoria de setup más exigente empieza en `dut.b_q[0]` y termina en `dut.Z`; `slack = +43,74 ns` con reloj objetivo de 100 ns. La ruta de hold más exigente se observa entre `dut.valid_q` y `dut.valid_out` con `slack = +0,35 ns`. Estos valores corresponden a las condiciones evaluadas y no validan automáticamente todas las esquinas PVT.

## 7. Evolución física y límites del análisis

| Etapa | Área de celdas aproximada |
|---|---:|
| Síntesis ORFS | 17 332,87 µm² |
| Floorplan | 18 279 µm² |
| Placement | 18 519 µm² |
| CTS / final | 18 798 µm² |

El incremento global es aproximadamente **8,45 %**; no equivale al área total del die. El timing publicado compara **floorplan (20,41 MHz)** frente a **post-routing (17,77 MHz)**. Falta una comparación directa de timing inmediatamente tras síntesis con idénticas restricciones y criterio de análisis.

El flujo físico abierto produjo GDSII. La verificación final reportó **DRC = 0** y **LVS con netlists coincidentes**. Son resultados de las herramientas/reglas utilizadas, no certificación de tape-out o fabricación.

## 8. Evidencia para reproducibilidad

Código: `rtl/`, `tb/`, `physical/orfs/`.

Scripts: `scripts/run_verilator.sh`, `scripts/run_yosys.sh`, `scripts/synth_sky130.tcl`, `scripts/synth_sky130.ys`.

El repositorio documenta alternativas abiertas (Verilator, Yosys, OpenROAD, KLayout). No se ejecutaron Design Compiler, ICC2, VCS ni Verdi en este flujo; sus resultados no deben atribuirse a estas herramientas.

### Estado de requisitos comprobado (noviembre de 2026)

1. **Parametrización funcional:** completadas pruebas con `WIDTH=8`, `WIDTH=16` y `WIDTH=32`, 1 656 vectores por configuración (4 968 PASS en conjunto). Los estímulos de 32 bits reutilizan algunas constantes de 16 bits; no constituyen cobertura exhaustiva del rango.
2. **Triestado RTL:** simulación de `tristate_demo.sv` completada con Icarus Verilog, buses `Z` cuando están deshabilitados; evidencia en [captura de GTKWave](screenshots/01_simulation/tristate_waveform.png). No es triestado interno en el ASIC.
3. **Entregables publicados:** netlist de síntesis, netlist post-routing, GDSII, OpenDB y SDC están disponibles en [deliverables](../deliverables).
4. **Pendiente de medición:** STA inmediatamente posterior a síntesis, con Liberty y condiciones declaradas, para compararlo justificadamente con post-routing. Se publicaron [instrucciones y limitaciones](reporte_tecnico_verificacion.md) y el script para realizarlo.
5. **Pendiente de revisión:** cobertura de restricciones del reset asíncrono, revisión de recuperación/remoción y aceptación académica de las herramientas abiertas y la sustitución del triestado interno.
