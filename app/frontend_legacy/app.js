const API_BASE_URL = 'https://tiendacomputo-api.azurewebsites.net/api';
let currentProducts = [];
let editingId = null;

async function loadProducts() {
    const res = await fetch(API_BASE_URL + '/articulos');
    currentProducts = await res.json();
    const list = document.getElementById('productsList');
    list.innerHTML = currentProducts.map(p => `
        <div class="product-card">
            <img src="https://picsum.photos/300/200?random=${p.id}random=${p.id}category=technology" style="width:100%; border-radius:4px;">
            <h3 class="product-name">${p.name}</h3>
            <p>${p.description}</p>
            <p>Precio: $${p.price}</p>
            <div style="display:flex; gap:10px;">
                <button class="btn-edit" onclick="editProduct(${p.id})">Editar</button>
                <button class="btn-danger" onclick="deleteProduct(${p.id})">Eliminar</button>
            </div>
        </div>
    `).join('');
}

document.addEventListener('DOMContentLoaded', () => {
    loadProducts();
    document.getElementById('addProductBtn').onclick = () => {
        editingId = null;
        document.getElementById('productForm').reset();
        document.getElementById('productModal').classList.add('show');
    };
    
    document.getElementById('productForm').onsubmit = async (e) => {
        e.preventDefault();
        const data = {
            name: document.getElementById('productName').value,
            description: document.getElementById('productDescription').value,
            price: document.getElementById('productPrice').value,
            stock: document.getElementById('productStock').value
        };
        
        const method = editingId ? 'PUT' : 'POST';
        const url = editingId ? `${API_BASE_URL}/articulos/${editingId}` : `${API_BASE_URL}/articulos`;
        
        await fetch(url, {
            method: method,
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(data)
        });
        document.getElementById('productModal').classList.remove('show');
        loadProducts();
    };
});

window.editProduct = (id) => {
    editingId = id;
    const p = currentProducts.find(x => x.id == id);
    if(p) {
        document.getElementById('productName').value = p.name;
        document.getElementById('productDescription').value = p.description;
        document.getElementById('productPrice').value = p.price;
        document.getElementById('productStock').value = p.stock;
        document.getElementById('productModal').classList.add('show');
    }
};

window.deleteProduct = async (id) => {
    if(confirm('¿Eliminar?')) {
        await fetch(API_BASE_URL + '/articulos/' + id, {method: 'DELETE'});
        loadProducts();
    }
};
