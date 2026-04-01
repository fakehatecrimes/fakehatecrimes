function timeout() {
  jQuery( window ).resize();
};
window.setTimeout( function() {
  timeout();
}, 500 );
