/* Aplicación de Frontend para Gestión de Inventario
   ITI-522 Proyecto 2 - Tienda de Computo */

// Configuración
const API_BASE_URL = 'https://tiendacomputo-api.azurewebsites.net/api';

// Estado de la aplicación
let products = [];
let editingProductId = null;

// Elementos del DOM
const productsList = document.getElementById('productsList');
const addProductBtn = document.getElementById('addProductBtn');
const productModal = document.getElementById('productModal');
const modalTitle = document.getElementById('modalTitle');
const productForm = document.getElementById('productForm');
const cancelBtn = document.getElementById('cancelBtn');
const saveBtn = document.getElementById('saveBtn');
const deleteModal = document.getElementById('deleteModal');
const deleteMessage = document.getElementById('deleteMessage');
const cancelDeleteBtn = document.getElementById('cancelDeleteBtn');
const confirmDeleteBtn = document.getElementById('confirmDeleteBtn');

// Inicialización
document.addEventListener('DOMContentLoaded', () => {
  loadProducts();
  setupEventListeners();
});

// Cargar productos desde la API
async function loadProducts() {
  try {
    showLoading();
    const response = await fetch(`${API_BASE_URL}/articulos`);
    if (!response.ok) {
      throw new Error(`Error HTTP: ${response.status}`);
    }
    products = await response.json();
    renderProducts();
  } catch (error) {
    console.error('Error al cargar productos:', error);
    showError('No se pudo cargar la lista de productos. Verifique la conexión y que el servidor esté en ejecución.');
  }
}

// Mostrar estado de carga
function showLoading() {
  productsList.innerHTML = '<p class="loading">Cargando productos...</p>';
}

// Mostrar mensaje de error
function showError(message) {
  productsList.innerHTML = `<p class="empty-state">${message}</p>`;
}

// Renderizar lista de productos
function renderProducts() {
  if (products.length === 0) {
    productsList.innerHTML = '<p class="empty-state">No hay productos registrados.</p>';
    return;
  }

  productsList.innerHTML = ''; // Limpiar

  products.forEach(product => {
    const card = document.createElement('div');
    card.className = 'product-card';

    // Usar una imagen placeholder o generar una basada en el ID
    const imageUrl = `https://picsum.photos/seed/${product.id}/400/300`;

    card.innerHTML = `
      <img src="${imageUrl}" alt="${product.nombre || product.name}" class="product-image">
      <div class="product-info">
        <h3 class="product-name">${product.nombre || product.name || 'Sin nombre'}</h3>
        <p class="product-description">${product.descripcion || product.description || 'Sin descripción disponible'}</p>
        <div class="product-details">
          <span class="product-price">$${parseFloat(product.precio || product.price || 0).toFixed(2)}</span>
          <span class="product-stock">Stock: ${product.stock || 0}</span>
        </div>
        <div class="product-actions">
          <button class="btn btn-secondary edit-btn" data-id="${product.id}">✏️ Editar</button>
          <button class="btn btn-danger delete-btn" data-id="${product.id}">🗑️ Eliminar</button>
        </div>
      </div>
    `;

    productsList.appendChild(card);
  });

  // Agregar event listeners a los botones de acción
  document.querySelectorAll('.edit-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const id = parseInt(e.target.dataset.id);
      editProduct(id);
    });
  });

  document.querySelectorAll('.delete-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const id = parseInt(e.target.dataset.id);
      deleteProduct(id);
    });
  });
}

// Mostrar modal para agregar nuevo producto
function showAddProductModal() {
  editingProductId = null;
  modalTitle.textContent = 'Nuevo Producto';
  productForm.reset();
  openModal();
}

// Mostrar modal para editar producto existente
function editProduct(id) {
  editingProductId = id;
  modalTitle.textContent = 'Editar Producto';

  const product = products.find(p => p.id === id);
  if (product) {
    document.getElementById('productName').value = product.nombre || product.name || '';
    document.getElementById('productDescription').value = product.descripcion || product.description || '';
    document.getElementById('productPrice').value = product.precio !== undefined ? product.precio : (product.price || 0);
    document.getElementById('productStock').value = product.stock !== undefined ? product.stock : 0;
    openModal();
  }
}

// Abrir modal
function openModal() {
  productModal.style.display = 'block';
}

// Cerrar modal
function closeModal() {
  productModal.style.display = 'none';
  productForm.reset();
  editingProductId = null;
}

// Mostrar modal de confirmación de eliminación
function showDeleteConfirmation(id) {
  const product = products.find(p => p.id === id);
  if (product) {
    deleteMessage.textContent = `¿Está seguro de que desea eliminar "${product.nombre || product.name}"?`;
    // Guardar el ID en el botón de confirmación mediante dataset
    confirmDeleteBtn.dataset.id = id;
    deleteModal.style.display = 'block';
  }
}

// Cerrar modal de eliminación
function closeDeleteModal() {
  deleteModal.style.display = 'none';
  confirmDeleteBtn.dataset.id = '';
}

// Manejar envío del formulario (agregar/editar)
productForm.addEventListener('submit', async (e) => {
  e.preventDefault();

  const productData = {
    name: document.getElementById('productName').value.trim(),
    description: document.getElementById('productDescription').value.trim(),
    price: parseFloat(document.getElementById('productPrice').value),
    stock: parseInt(document.getElementById('productStock').value)
  };

  // Validación básica
  if (!productData.name || isNaN(productData.price) || isNaN(productData.stock)) {
    showFormMessage('Por favor, complete todos los campos requeridos.', 'error');
    return;
  }

  try {
    if (editingProductId === null) {
      // Crear nuevo producto
      const response = await fetch(`${API_BASE_URL}/articulos`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(productData)
      });

      if (!response.ok) {
        throw new Error(`Error al crear: ${response.status}`);
      }

      const newProduct = await response.json();
      products.push(newProduct);
      showFormMessage('Producto creado exitosamente.', 'success');
    } else {
      // Actualizar producto existente
      const response = await fetch(`${API_BASE_URL}/articulos/${editingProductId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(productData)
      });

      if (!response.ok) {
        throw new Error(`Error al actualizar: ${response.status}`);
      }

      const updatedProduct = await response.json();
      const index = products.findIndex(p => p.id === editingProductId);
      if (index !== -1) {
        products[index] = updatedProduct;
      }
      showFormMessage('Producto actualizado exitosamente.', 'success');
    }

    // Cerrar modal y recargar lista
    closeModal();
    await loadProducts();
  } catch (error) {
    console.error('Error al guardar producto:', error);
    showFormMessage('Error al guardar el producto. Inténtelo nuevamente.', 'error');
  }
});

// Mostrar mensaje en el formulario
function showFormMessage(message, type) {
  // Eliminar mensajes existentes
  const existingMsg = productForm.querySelector('.form-message');
  if (existingMsg) {
    existingMsg.remove();
  }

  const msgDiv = document.createElement('div');
  msgDiv.className = `form-message ${type}`;
  msgDiv.textContent = message;
  msgDiv.style.padding = '10px';
  msgDiv.style.marginBottom = '15px';
  msgDiv.style.borderRadius = '4px';
  msgDiv.style.textAlign = 'center';
  msgDiv.style.fontWeight = 'bold';
  
  if (type === 'success') {
    msgDiv.style.backgroundColor = '#d4edda';
    msgDiv.style.color = '#155724';
  } else {
    msgDiv.style.backgroundColor = '#f8d7da';
    msgDiv.style.color = '#721c24';
  }

  // Insertar al inicio del formulario
  productForm.prepend(msgDiv);

  // Eliminar automáticamente después de 3 segundos
  setTimeout(() => {
    if (msgDiv.parentNode) {
      msgDiv.parentNode.removeChild(msgDiv);
    }
  }, 3000);
}

// // Restauración manual
// const restoreBtn = document.getElementById('restoreBtn');
// restoreBtn.addEventListener('click', async () => {
//   const confirm = window.confirm('¡ATENCIÓN! Esto sobreescribirá los datos actuales con el último backup. ¿Está seguro?');
//   if (!confirm) return;
//   
//   try {
//     const response = await fetch(`${API_BASE_URL}/restore`, {
//       method: 'POST'
//     });
//     if (response.ok) {
//       alert('Restauración exitosa. La página se recargará.');
//       window.location.reload();
//     } else {
//       alert('Error al restaurar');
//     }
//   } catch (error) {
//     console.error('Error:', error);
//   }
// });

// Eliminar producto
function deleteProduct(id) {
  showDeleteConfirmation(id);
}

// Manejar confirmación de eliminación
confirmDeleteBtn.addEventListener('click', async () => {
  const id = parseInt(confirmDeleteBtn.dataset.id);
  if (!id) return;

  try {
    closeDeleteModal();
    showLoading(); // Mostrar carga mientras se elimina

    const response = await fetch(`${API_BASE_URL}/articulos/${id}`, {
      method: 'DELETE'
    });

    if (!response.ok) {
      throw new Error(`Error al eliminar: ${response.status}`);
    }

    // Eliminar de la lista local
    products = products.filter(p => p.id !== id);
    renderProducts();

    // Mostrar notificación temporal
    showTempMessage('Producto eliminado correctamente.', 'success');
  } catch (error) {
    console.error('Error al eliminar producto:', error);
    showTempMessage('Error al eliminar el producto.', 'error');
  }
});

// Mostrar mensaje temporal en la parte superior
function showTempMessage(message, type) {
  // Eliminar cualquier mensaje existente
  const existing = document.querySelector('.temp-message');
  if (existing) existing.remove();

  const msg = document.createElement('div');
  msg.className = `temp-message ${type}`;
  msg.textContent = message;
  msg.style.position = 'fixed';
  msg.style.top = '1rem';
  msg.style.right = '1rem';
  msg.style.padding = '1rem 1.5rem';
  msg.style.borderRadius = '4px';
  msg.style.boxShadow = '0 4px 6px rgba(0,0,0,0.1)';
  msg.style.zIndex = '2000';
  msg.style.fontSize = '1rem';
  msg.style.fontWeight = '600';

  if (type === 'success') {
    msg.style.backgroundColor = '#d4edda';
    msg.style.color = '#155724';
    msg.style.border = '1px solid #c3e6cb';
  } else {
    msg.style.backgroundColor = '#f8d7da';
    msg.style.color = '#721c24';
    msg.style.border = '1px solid #f5c6cb';
  }

  document.body.appendChild(msg);

  // Eliminar después de 3 segundos
  setTimeout(() => {
    if (msg.parentNode) {
      msg.parentNode.removeChild(msg);
    }
  }, 3000);
}

// Event Listeners
function setupEventListeners() {
  // Botón de nuevo producto
  addProductBtn.addEventListener('click', showAddProductModal);

  // Botones de cancelar en modales
  cancelBtn.addEventListener('click', closeModal);
  document.getElementById('closeModal').addEventListener('click', closeModal);
  cancelDeleteBtn.addEventListener('click', closeDeleteModal);
  document.getElementById('closeDeleteModal').addEventListener('click', closeDeleteModal);

  // Cerrar modales al hacer clic fuera del contenido
  window.addEventListener('click', (e) => {
    if (e.target === productModal) {
      closeModal();
    }
    if (e.target === deleteModal) {
      closeDeleteModal();
    }
  });

  // Tecla Escape para cerrar modales
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      if (productModal.style.display === 'block') {
        closeModal();
      }
      if (deleteModal.style.display === 'block') {
        closeDeleteModal();
      }
    }
  });
}

// Exportar funciones para pruebas (opcional, si se usa en un entorno de módulos)
if (typeof exports !== 'undefined') {
  module.exports = {
    loadProducts,
    renderProducts,
    showAddProductModal,
    editProduct,
    closeModal,
    closeDeleteModal,
    showDeleteConfirmation
  };
};