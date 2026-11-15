# ATLANIA — Kit Portátil de Exposición al Jurado (NASA Space Apps 2026)

Repositorio autónomo listo para abrir la presentación 3D (`index.html`), revisar el guion/Q&A (`BRIEFING_QA_JURADO.md`) y dejar lista cualquier laptop para proyectar por HDMI.

---

## Instrucciones para Antigravity en la PC de exposición

Si estás ejecutando Antigravity en la laptop que se conectará al proyector HDMI, sigue estos pasos automáticamente:

### 1. Levantar las diapositivas 3D (`http://localhost:8090`)
```bash
chmod +x iniciar_exposicion.sh
./iniciar_exposicion.sh 8090
```
- Todas las texturas planetarias (`assets/nasa/`), tipografía `Hello Paris` (`assets/fonts/`), emblema (`assets/brand/`) y motor WebGL (`assets/vendor/three.min.js`) están incluidos localmente para funcionar **incluso sin internet**.
- Navegación en escenario: `F11` (pantalla completa) y flechas `←` / `→` o `Espacio`.

### 2. Levantar el Explorador 3D en vivo (`http://localhost:3000/explorer`)
Para que el botón **`ABRIR EXPLORADOR ↗`** y la lámina 5 de Demo en Vivo abran la aplicación interactiva:
```bash
git clone https://github.com/FakeCxbas/Atlania.git ../Atlania
cd ../Atlania/frontend
npm install
npm run dev
```
- Asegúrate de dejar abierta en otra pestaña `http://localhost:3000/explorer` antes de salir al escenario.

### 3. Preparación rápida para salida HDMI
- Verificar pantallas conectadas (`xrandr --query` en X11 o `hyprctl monitors` en Hyprland/Wayland).
- Configurar resolución `1920x1080` (16:9) duplicada o extendida según prefiera el presentador.
- Desactivar suspensión de pantalla / salvapantallas durante la presentación (`xdg-screensaver suspend` o equivalente).

---

## Contenido del paquete

| Archivo | Descripción |
| :--- | :--- |
| `index.html` | Presentación interactiva de 7 láminas con escena 3D WebGL (Tierra, Luna, Marte y malla Copernicus DEM). |
| `BRIEFING_QA_JURADO.md` | Guion de 2:25 para 4 personas, cifras verificadas del código y banco completo de preguntas difíciles del jurado. |
| `iniciar_exposicion.sh` | Script que levanta el servidor local y abre las diapositivas en el navegador. |
| `assets/` | Fuentes (`Hello Paris`), texturas NASA, recortes de satélites y `three.min.js` local. |
