/* Stillora landing — nav stick + current year. Reveal animations are pure CSS. */
(function(){
  var nav = document.querySelector('.nav');
  function onScroll(){ if(nav) nav.classList.toggle('stuck', window.scrollY > 12); }
  onScroll();
  window.addEventListener('scroll', onScroll, { passive:true });

  var y = document.getElementById('yr');
  if(y) y.textContent = new Date().getFullYear();
})();
