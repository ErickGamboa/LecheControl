// Da de baja el service worker que dejó la app cuando vivía en la raíz.
//
// POR QUÉ EXISTE ESTO
//
// Hasta que se publicó el sitio, la app Flutter se servía en `/`, y Flutter
// registra un service worker con el alcance de donde está: `/`, o sea **todo
// el dominio**. Ese service worker se queda instalado en el navegador de
// quien ya entró alguna vez, y sigue contestando desde su caché.
//
// Al mudar la app a `/app/`, el de la raíz quedó huérfano pero vivo: sigue
// interceptando y sirviendo los archivos viejos de la app. Para el que nunca
// entró no pasa nada —nunca lo instaló—, pero al que ya la usaba se le rompe
// el sitio y la app. Justo el patrón que apareció: cuenta nueva bien, cuenta
// de siempre mal.
//
// Flutter tampoco lo actualiza solo: para saber si cambió, pide
// `/flutter_service_worker.js`, que en la raíz ya no existe. Da 404, la
// actualización falla y se queda con el caché viejo para siempre.
//
// Así que hay que darlo de baja a mano. Se toca **solo el de la raíz**: el de
// `/app/` es el de la app y es el que le da el modo sin conexión.
(function () {
  if (!('serviceWorker' in navigator)) return;

  var YA_LIMPIE = 'lc_sw_limpiado';

  navigator.serviceWorker
    .getRegistrations()
    .then(function (registros) {
      var viejos = registros.filter(function (r) {
        try {
          return new URL(r.scope).pathname === '/';
        } catch (e) {
          return false;
        }
      });
      if (viejos.length === 0) return null;

      return Promise.all(
        viejos.map(function (r) {
          return r.unregister();
        })
      )
        .then(function () {
          // El caché va aparte del registro: sin borrarlo, los archivos
          // viejos siguen ocupando espacio y pueden volver a servirse.
          if (!window.caches) return null;
          return caches.keys().then(function (nombres) {
            return Promise.all(
              nombres.map(function (n) {
                return caches.delete(n);
              })
            );
          });
        })
        .then(function () {
          // Si esta misma página vino del caché viejo, darlo de baja no la
          // arregla: hay que volver a pedirla. Una sola vez —el centinela en
          // sessionStorage evita quedar en un bucle de recargas.
          try {
            if (sessionStorage.getItem(YA_LIMPIE)) return;
            sessionStorage.setItem(YA_LIMPIE, '1');
          } catch (e) {
            return; // navegador sin sessionStorage: mejor no recargar
          }
          location.reload();
        });
    })
    .catch(function () {
      // Que esto falle no puede tumbar la página: es una limpieza, no una
      // función del sitio.
    });
})();
