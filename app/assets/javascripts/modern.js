// Modern JavaScript for fakehatecrimes.org

document.addEventListener('DOMContentLoaded', function() {
  
  // Add smooth scrolling to all links
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      e.preventDefault();
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        target.scrollIntoView({
          behavior: 'smooth',
          block: 'start'
        });
      }
    });
  });

  // Add loading states to forms
  document.querySelectorAll('form').forEach(form => {
    form.addEventListener('submit', function() {
      const submitBtn = this.querySelector('input[type="submit"], button[type="submit"]');
      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<span class="loading"></span> Saving...';
      }
    });
  });

  // Add hover effects to cards
  document.querySelectorAll('.card').forEach(card => {
    card.addEventListener('mouseenter', function() {
      this.style.transform = 'translateY(-5px)';
    });
    
    card.addEventListener('mouseleave', function() {
      this.style.transform = 'translateY(0)';
    });
  });

  // Add confirmation for delete buttons
  document.querySelectorAll('.btn-danger').forEach(btn => {
    btn.addEventListener('click', function(e) {
      if (!confirm('Are you sure you want to delete this item?')) {
        e.preventDefault();
      }
    });
  });

  // Auto-resize textareas
  document.querySelectorAll('textarea').forEach(textarea => {
    textarea.addEventListener('input', function() {
      this.style.height = 'auto';
      this.style.height = this.scrollHeight + 'px';
    });
  });

  // Add tooltips for auto-linked URLs
  document.querySelectorAll('.auto-link').forEach(link => {
    link.title = 'Click to open in new tab';
  });

  // Add search highlighting
  const urlParams = new URLSearchParams(window.location.search);
  const searchTerm = urlParams.get('search');
  if (searchTerm) {
    highlightSearchTerm(searchTerm);
  }

  // Add keyboard shortcuts
  document.addEventListener('keydown', function(e) {
    // Ctrl/Cmd + Enter to submit forms
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
      const activeForm = document.querySelector('form:focus-within');
      if (activeForm) {
        const submitBtn = activeForm.querySelector('input[type="submit"], button[type="submit"]');
        if (submitBtn) {
          submitBtn.click();
        }
      }
    }
    
    // Escape to close modals or clear forms
    if (e.key === 'Escape') {
      const modals = document.querySelectorAll('.modal');
      modals.forEach(modal => {
        if (modal.style.display === 'block') {
          modal.style.display = 'none';
        }
      });
    }
  });

  // Add responsive navigation toggle for mobile
  const navToggle = document.querySelector('.nav-toggle');
  const nav = document.querySelector('#nav');
  
  if (navToggle && nav) {
    navToggle.addEventListener('click', function() {
      nav.classList.toggle('nav-open');
    });
  }

  // Add smooth transitions for page loads
  document.body.style.opacity = '0';
  setTimeout(() => {
    document.body.style.transition = 'opacity 0.3s ease-in-out';
    document.body.style.opacity = '1';
  }, 100);

});

// Function to highlight search terms
function highlightSearchTerm(term) {
  const walker = document.createTreeWalker(
    document.body,
    NodeFilter.SHOW_TEXT,
    null,
    false
  );

  const textNodes = [];
  let node;
  while (node = walker.nextNode()) {
    textNodes.push(node);
  }

  textNodes.forEach(textNode => {
    const text = textNode.textContent;
    const regex = new RegExp(`(${term})`, 'gi');
    if (regex.test(text)) {
      const highlightedText = text.replace(regex, '<mark>$1</mark>');
      const span = document.createElement('span');
      span.innerHTML = highlightedText;
      textNode.parentNode.replaceChild(span, textNode);
    }
  });
}

// Function to show notifications
function showNotification(message, type = 'info') {
  const notification = document.createElement('div');
  notification.className = `notification notification-${type}`;
  notification.textContent = message;
  
  notification.style.cssText = `
    position: fixed;
    top: 20px;
    right: 20px;
    padding: 15px 20px;
    border-radius: 8px;
    color: white;
    font-weight: 600;
    z-index: 1000;
    transform: translateX(100%);
    transition: transform 0.3s ease-in-out;
  `;
  
  if (type === 'success') {
    notification.style.background = 'linear-gradient(135deg, #27ae60, #2ecc71)';
  } else if (type === 'error') {
    notification.style.background = 'linear-gradient(135deg, #e74c3c, #e67e22)';
  } else {
    notification.style.background = 'linear-gradient(135deg, #3498db, #2980b9)';
  }
  
  document.body.appendChild(notification);
  
  setTimeout(() => {
    notification.style.transform = 'translateX(0)';
  }, 100);
  
  setTimeout(() => {
    notification.style.transform = 'translateX(100%)';
    setTimeout(() => {
      document.body.removeChild(notification);
    }, 300);
  }, 3000);
}

// Function to format dates nicely
function formatDate(dateString) {
  const date = new Date(dateString);
  const now = new Date();
  const diffTime = Math.abs(now - date);
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  
  if (diffDays === 1) {
    return 'Yesterday';
  } else if (diffDays < 7) {
    return `${diffDays} days ago`;
  } else {
    return date.toLocaleDateString();
  }
}

// Add CSS for search highlighting
const style = document.createElement('style');
style.textContent = `
  mark {
    background: linear-gradient(135deg, #f39c12, #f1c40f);
    color: #2c3e50;
    padding: 2px 4px;
    border-radius: 3px;
    font-weight: 600;
  }
  
  .notification {
    box-shadow: 0 4px 15px rgba(0,0,0,0.2);
  }
  
  .nav-toggle {
    display: none;
  }
  
  @media (max-width: 768px) {
    .nav-toggle {
      display: block;
      background: none;
      border: none;
      color: white;
      font-size: 1.5rem;
      cursor: pointer;
      padding: 10px;
    }
    
    #nav {
      display: none;
    }
    
    #nav.nav-open {
      display: block;
    }
  }
`;
document.head.appendChild(style);
