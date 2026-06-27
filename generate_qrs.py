import qrcode
import json
import os

# 1. Define your list of products with image links (as lists to match Flutter model)
products = [
  {
    "sku": "CLO-1001",
    "price": 29.99,
    "cost": 12.50,
    "name": "T-shirt coton premium (noir)",
    "category": "Clothing",
    "quantity": 180,
    "supplier": "Atlas Fashion"
  },
  {
    "sku": "ELEC-2001",
    "price": 249.00,
    "cost": 165.00,
    "name": "Casque Bluetooth ANC",
    "category": "Electronics",
    "quantity": 60,
    "supplier": "TechSource Maroc"
  },
  {
    "sku": "FOOD-3001",
    "price": 6.49,
    "cost": 2.10,
    "name": "Huile d’olive extra vierge 500ml",
    "category": "Food",
    "quantity": 220,
    "supplier": "Terroir Select"
  },
  {
    "sku": "FURN-4001",
    "price": 129.00,
    "cost": 78.00,
    "name": "Chaise scandinave en bois",
    "category": "Furniture",
    "quantity": 35,
    "supplier": "CasaWood"
  },
  {
    "sku": "GADG-5001",
    "price": 39.99,
    "cost": 18.00,
    "name": "Support téléphone magnétique (voiture)",
    "category": "Gadgets",
    "quantity": 140,
    "supplier": "GadgetHub"
  },
  {
    "sku": "CLO-1002",
    "price": 49.99,
    "cost": 22.00,
    "name": "Hoodie oversize (gris)",
    "category": "Clothing",
    "quantity": 95,
    "supplier": "UrbanWear"
  },
  {
    "sku": "ELEC-2002",
    "price": 119.00,
    "cost": 74.00,
    "name": "Clavier mécanique RGB",
    "category": "Electronics",
    "quantity": 48,
    "supplier": "KeyPro Distribution"
  },
  {
    "sku": "FOOD-3002",
    "price": 3.99,
    "cost": 1.40,
    "name": "Café moulu 250g",
    "category": "Food",
    "quantity": 260,
    "supplier": "Roasters Co."
  },
  {
    "sku": "FURN-4002",
    "price": 199.00,
    "cost": 120.00,
    "name": "Table basse minimaliste",
    "category": "Furniture",
    "quantity": 18,
    "supplier": "Minimal Home"
  },
  {
    "sku": "GADG-5002",
    "price": 24.99,
    "cost": 9.50,
    "name": "Mini lampe LED rechargeable",
    "category": "Gadgets",
    "quantity": 210,
    "supplier": "BrightGear"
  },
  {
    "sku": "CLO-1003",
    "price": 79.00,
    "cost": 36.00,
    "name": "Veste denim classique",
    "category": "Clothing",
    "quantity": 55,
    "supplier": "DenimWorks"
  },
  {
    "sku": "ELEC-2003",
    "price": 69.99,
    "cost": 41.00,
    "name": "Souris gaming sans fil",
    "category": "Electronics",
    "quantity": 130,
    "supplier": "ProGaming Supply"
  },
  {
    "sku": "FOOD-3003",
    "price": 2.49,
    "cost": 0.95,
    "name": "Chocolat noir 70%",
    "category": "Food",
    "quantity": 340,
    "supplier": "Sweet & Co."
  },
  {
    "sku": "FURN-4003",
    "price": 349.00,
    "cost": 220.00,
    "name": "Bibliothèque chêne 5 étagères",
    "category": "Furniture",
    "quantity": 12,
    "supplier": "OakLine"
  },
  {
    "sku": "GADG-5003",
    "price": 59.00,
    "cost": 28.00,
    "name": "Chargeur rapide USB-C 65W",
    "category": "Gadgets",
    "quantity": 170,
    "supplier": "PowerMate"
  }
]



# Create a folder for the images if it doesn't exist
output_folder = "product_qrs"
if not os.path.exists(output_folder):
    os.makedirs(output_folder)

print(f"Generating {len(products)} QR codes...")

for product in products:
    # 2. Convert the product dictionary to a JSON string
    json_data = json.dumps(product, separators=(',', ':'))
    
    # 3. Create the QR code object
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    
    qr.add_data(json_data)
    qr.make(fit=True)

    # 4. Create an image from the QR Code instance
    img = qr.make_image(fill_color="black", back_color="white")

    # 5. Save the image
    filename = f"{output_folder}/{product['sku']}.png"
    img.save(filename)
    print(f"Saved: {filename}")

print(f"\nDone! Check the '{output_folder}' folder.")
