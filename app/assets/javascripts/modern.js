// Modern JavaScript for fakehatecrimes.org

document.addEventListener('DOMContentLoaded', function() {
  
  // Add smooth scrolling to all links
  var anchors = document.querySelectorAll('a[href^="#"]');
  for (var i = 0; i < anchors.length; i++) {
    anchors[i].addEventListener('click', function (e) {
      e.preventDefault();
      var target = document.querySelector(this.getAttribute('href'));
      if (target) {
        target.scrollIntoView({
          behavior: 'smooth',
          block: 'start'
        });
      }
    });
      };

  // Add loading states to forms
  /*
  document.querySelectorAll('form').forEach(function(form) {
    form.addEventListener('submit', function(e) {
      var submitBtn = this.querySelector('input[type="submit"], button[type="submit"]');
      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<span class="loading"></span> Saving...';
        
        // Allow the form to submit normally
        // The form will submit and the page will reload, so the disabled state won't matter
      }
    });
  });
  */

  // Add hover effects to cards
  document.querySelectorAll('.card').forEach(function(card) {
    card.addEventListener('mouseenter', function() {
      this.style.transform = 'translateY(-5px)';
    });
    
    card.addEventListener('mouseleave', function() {
      this.style.transform = 'translateY(0)';
    });
  });

  // Add confirmation for delete buttons
  document.querySelectorAll('.btn-danger').forEach(function(btn) {
    btn.addEventListener('click', function(e) {
      if (!confirm('Are you sure you want to delete this item?')) {
        e.preventDefault();
      }
    });
  });

  // Add responsive navigation toggle for mobile
  var navToggle = document.querySelector('.nav-toggle');
  var nav = document.querySelector('#nav');
  
  if (navToggle && nav) {
    navToggle.addEventListener('click', function() {
      nav.classList.toggle('nav-open');
    });
  }

  // Add smooth transitions for page loads
  document.body.style.opacity = '0';
  setTimeout(function() {
    document.body.style.transition = 'opacity 0.3s ease-in-out';
    document.body.style.opacity = '1';
  }, 100);

});
