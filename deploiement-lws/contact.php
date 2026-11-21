<?php
/**
 * Formulaires du site NEXUS International (amanexus.com), hébergement LWS.
 *
 * Un seul script pour tous les formulaires (contact, Business Services, ARZIKI,
 * Desk Algérie-Niger). Il :
 *  1. refuse les robots (champ piège invisible et délai minimal de saisie) ;
 *  2. contrôle et nettoie chaque champ ;
 *  3. envoie le message à nexusinternational25@gmail.com, copie à operation@amanexus.com ;
 *  4. renvoie la personne sur la page d'origine avec un message de réussite ou d'erreur.
 *
 * L'expéditeur est une adresse du domaine (meilleure arrivée dans Gmail) ; l'adresse
 * de la personne est mise en « Répondre à ».
 * Compatible PHP 8 (aucune fonction obsolète).
 */

const DESTINATAIRE = 'nexusinternational25@gmail.com';
const COPIE = 'operation@amanexus.com';
const EXPEDITEUR = 'site@amanexus.com';
const DELAI_MINIMUM = 3; // secondes entre l'affichage et l'envoi

// Pages autorisées pour le retour (évite toute redirection vers un autre site).
// Chemins relatifs au dossier du site : le site marche aussi dans un dossier de test.
const PAGES = [
    'index.html', 'contact.html', 'services.html', 'arziki.html', 'algerie-niger.html',
    'formations.html', 'expertises.html',
    'en/', 'en/contact.html', 'en/services.html', 'en/arziki.html',
    'en/algerie-niger.html', 'en/formations.html', 'en/expertises.html',
    'ar/algerie-niger.html',
];

function retour(string $etat): void {
    $page = $_POST['page'] ?? 'contact.html';
    if (!in_array($page, PAGES, true)) {
        $page = 'contact.html';
    }
    $dossier = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '/')), '/');
    header('Location: ' . $dossier . '/' . $page . '?envoi=' . $etat . '#formulaire', true, 303);
    exit;
}

function champ(string $nom, int $max = 200): string {
    $v = trim((string)($_POST[$nom] ?? ''));
    $v = str_replace(["\r", "\0"], '', $v);
    return mb_substr($v, 0, $max);
}

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    retour('erreur');
}

// 1. Anti-spam : champ piège rempli, ou formulaire envoyé trop vite.
if (champ('site_web') !== '') {
    retour('ok'); // on ne prévient pas le robot
}
$affiche = (int)champ('t', 20);
if ($affiche > 0 && (time() - intdiv($affiche, 1000)) < DELAI_MINIMUM) {
    retour('ok');
}

// 2. Contrôles.
$nom = champ('nom', 120);
$email = champ('email', 160);
$telephone = champ('telephone', 40);
$entreprise = champ('entreprise', 160);
$pays = champ('pays', 60);
$besoin = champ('besoin', 120);
$dates = champ('dates', 80);
$message = champ('message', 5000);
$formulaire = champ('formulaire', 60);
$langue = champ('langue', 5);
$consentement = champ('consentement', 5);

if (mb_strlen($nom) < 2 || mb_strlen($message) < 10 || $consentement !== 'oui') {
    retour('erreur');
}
if ($email !== '' && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    retour('erreur');
}
if ($email === '' && $telephone === '') {
    retour('erreur');
}

// 3. Envoi.
$sujet = 'Site amanexus.com : ' . ($formulaire !== '' ? $formulaire : 'contact') . ' (' . $nom . ')';
$corps = "Nouveau message depuis le site amanexus.com\n\n"
    . "Formulaire : $formulaire\n"
    . "Langue : $langue\n"
    . "Nom : $nom\n"
    . "E-mail : $email\n"
    . "Téléphone : $telephone\n"
    . "Entreprise : $entreprise\n"
    . "Pays : $pays\n"
    . "Besoin : $besoin\n"
    . "Dates prévues : $dates\n\n"
    . "Message :\n$message\n";

$entetes = [
    'From' => 'Site NEXUS International <' . EXPEDITEUR . '>',
    'Cc' => COPIE,
    'MIME-Version' => '1.0',
    'Content-Type' => 'text/plain; charset=UTF-8',
    'X-Mailer' => 'amanexus.com',
];
if ($email !== '') {
    $entetes['Reply-To'] = $email;
}

$sujetEncode = '=?UTF-8?B?' . base64_encode($sujet) . '?=';
$envoye = mail(DESTINATAIRE, $sujetEncode, $corps, $entetes, '-f' . EXPEDITEUR);

retour($envoye ? 'ok' : 'erreur');
