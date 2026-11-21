// Site NEXUS International : menu mobile, horodatage anti-robot des formulaires,
// message après l'envoi d'un formulaire. Aucun traceur, aucune bibliothèque.
(function () {
  var d = document;
  var entete = d.querySelector('.entete');
  var burger = d.querySelector('.burger');
  if (burger) {
    burger.addEventListener('click', function () {
      var ouvert = entete.classList.toggle('ouvert');
      burger.setAttribute('aria-expanded', ouvert ? 'true' : 'false');
    });
  }

  // Heure d'affichage du formulaire : un robot qui envoie en moins de 3 s est ignoré.
  d.querySelectorAll('input[name="t"]').forEach(function (c) { c.value = String(Date.now()); });

  // Message après l'envoi (paramètre ?envoi=ok ou ?envoi=erreur).
  var etat = new URLSearchParams(location.search).get('envoi');
  var zone = d.getElementById('message-envoi');
  if (etat && zone) {
    zone.hidden = false;
    zone.className = 'message-envoi ' + (etat === 'ok' ? 'ok' : 'ko');
    zone.textContent = zone.getAttribute(etat === 'ok' ? 'data-ok' : 'data-ko');
  }
})();
