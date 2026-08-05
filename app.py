
#Uses only Python's standard-library sqlite3 module.

from __future__ import annotations

import sqlite3
from pathlib import Path
from typing import Iterable

BASE_DIR = Path(__file__).resolve().parent
DB_PATH = BASE_DIR / "ecommerce.db"
SCHEMA_PATH = BASE_DIR / "ecommerce_database.sql"


def connect() -> sqlite3.Connection:
    connection = sqlite3.connect(DB_PATH)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    return connection


def initialize_database(reset: bool = False) -> None:
    if reset and DB_PATH.exists():
        DB_PATH.unlink()
    if not DB_PATH.exists():
        if not SCHEMA_PATH.exists():
            raise FileNotFoundError(f"Missing SQL file: {SCHEMA_PATH}")
        with connect() as conn:
            conn.executescript(SCHEMA_PATH.read_text(encoding="utf-8"))
        print("Database created and sample data loaded.")


def print_rows(rows: Iterable[sqlite3.Row]) -> None:
    rows = list(rows)
    if not rows:
        print("No matching records found.")
        return
    headers = list(rows[0].keys())
    widths = {h: max(len(h), *(len(str(r[h])) for r in rows)) for h in headers}
    print(" | ".join(h.ljust(widths[h]) for h in headers))
    print("-+-".join("-" * widths[h] for h in headers))
    for row in rows:
        print(" | ".join(str(row[h]).ljust(widths[h]) for h in headers))


def view_products() -> None:
    with connect() as conn:
        rows = conn.execute(
            """SELECT ProductID, Name, Category,
                      printf('$%.2f', Price) AS Price, StockQuantity AS Stock
               FROM Product
               WHERE IsActive = 1
               ORDER BY Category, Name"""
        ).fetchall()
    print_rows(rows)


def search_products() -> None:
    keyword = input("Enter a product name or category keyword: ").strip()
    if not keyword:
        print("A search keyword is required.")
        return
    pattern = f"%{keyword}%"
    with connect() as conn:
        rows = conn.execute(
            """SELECT ProductID, Name, Category,
                      printf('$%.2f', Price) AS Price, StockQuantity AS Stock
               FROM Product
               WHERE IsActive = 1
                 AND (Name LIKE ? OR Category LIKE ?)
               ORDER BY Name""",
            (pattern, pattern),
        ).fetchall()
    print_rows(rows)


def add_product() -> None:
    try:
        name = input("Product name: ").strip()
        description = input("Description: ").strip()
        category = input("Category: ").strip()
        price = float(input("Price: "))
        stock = int(input("Starting stock quantity: "))
        if not name or not category or price < 0 or stock < 0:
            raise ValueError
        with connect() as conn:
            cursor = conn.execute(
                """INSERT INTO Product
                   (Name, Description, Category, Price, StockQuantity)
                   VALUES (?, ?, ?, ?, ?)""",
                (name, description, category, price, stock),
            )
        print(f"Product added with ID {cursor.lastrowid}.")
    except ValueError:
        print("Invalid input. Name/category are required and numbers cannot be negative.")
    except sqlite3.Error as exc:
        print(f"Database error: {exc}")


def restock_product() -> None:
    try:
        product_id = int(input("Product ID: "))
        quantity = int(input("Quantity to add: "))
        if quantity <= 0:
            raise ValueError
        with connect() as conn:
            cursor = conn.execute(
                """UPDATE Product
                   SET StockQuantity = StockQuantity + ?
                   WHERE ProductID = ? AND IsActive = 1""",
                (quantity, product_id),
            )
        print("Product restocked." if cursor.rowcount else "Active product not found.")
    except ValueError:
        print("Enter valid positive whole numbers.")


def create_purchase() -> None:
    try:
        customer_id = int(input("Customer ID: "))
        raw_staff = input("Staff ID (press Enter for none): ").strip()
        staff_id = int(raw_staff) if raw_staff else None
        items: dict[int, int] = {}
        print("Enter product IDs and quantities. Press Enter for product ID when finished.")
        while True:
            raw_product = input("Product ID: ").strip()
            if not raw_product:
                break
            product_id = int(raw_product)
            quantity = int(input("Quantity: "))
            if quantity <= 0:
                raise ValueError("Quantity must be positive.")
            items[product_id] = items.get(product_id, 0) + quantity
        if not items:
            print("A purchase must contain at least one product.")
            return

        with connect() as conn:
            conn.execute("BEGIN")
            customer = conn.execute(
                "SELECT CustomerID FROM Customer WHERE CustomerID = ?", (customer_id,)
            ).fetchone()
            if not customer:
                raise ValueError("Customer not found.")
            if staff_id is not None:
                staff = conn.execute(
                    "SELECT StaffID FROM Staff WHERE StaffID = ?", (staff_id,)
                ).fetchone()
                if not staff:
                    raise ValueError("Staff member not found.")

            product_rows = {}
            total = 0.0
            for product_id, quantity in items.items():
                product = conn.execute(
                    """SELECT ProductID, Name, Price, StockQuantity
                       FROM Product WHERE ProductID = ? AND IsActive = 1""",
                    (product_id,),
                ).fetchone()
                if not product:
                    raise ValueError(f"Active product {product_id} was not found.")
                if product["StockQuantity"] < quantity:
                    raise ValueError(
                        f"Not enough stock for {product['Name']}. "
                        f"Available: {product['StockQuantity']}."
                    )
                product_rows[product_id] = product
                total += product["Price"] * quantity

            cursor = conn.execute(
                """INSERT INTO Purchase (CustomerID, StaffID, Status, TotalAmount)
                   VALUES (?, ?, 'Paid', ?)""",
                (customer_id, staff_id, round(total, 2)),
            )
            purchase_id = cursor.lastrowid
            for product_id, quantity in items.items():
                product = product_rows[product_id]
                conn.execute(
                    """INSERT INTO PurchaseItem
                       (PurchaseID, ProductID, Quantity, UnitPrice)
                       VALUES (?, ?, ?, ?)""",
                    (purchase_id, product_id, quantity, product["Price"]),
                )
                conn.execute(
                    """UPDATE Product SET StockQuantity = StockQuantity - ?
                       WHERE ProductID = ?""",
                    (quantity, product_id),
                )
            conn.commit()
        print(f"Purchase {purchase_id} created. Total: ${total:.2f}")
    except (ValueError, sqlite3.Error) as exc:
        print(f"Purchase was not created: {exc}")


def purchase_history() -> None:
    try:
        customer_id = int(input("Customer ID: "))
    except ValueError:
        print("Enter a valid customer ID.")
        return
    with connect() as conn:
        rows = conn.execute(
            """SELECT pu.PurchaseID,
                      substr(pu.PurchaseDate, 1, 16) AS PurchaseDate,
                      pu.Status,
                      p.Name AS Product,
                      pi.Quantity,
                      printf('$%.2f', pi.UnitPrice) AS UnitPrice,
                      printf('$%.2f', pi.Quantity * pi.UnitPrice) AS LineTotal
               FROM Purchase pu
               JOIN PurchaseItem pi ON pu.PurchaseID = pi.PurchaseID
               JOIN Product p ON pi.ProductID = p.ProductID
               WHERE pu.CustomerID = ?
               ORDER BY pu.PurchaseDate DESC, pu.PurchaseID, p.Name""",
            (customer_id,),
        ).fetchall()
    print_rows(rows)


def sales_report() -> None:
    with connect() as conn:
        rows = conn.execute(
            """SELECT p.Name AS Product,
                      COALESCE(SUM(pi.Quantity), 0) AS UnitsSold,
                      printf('$%.2f', COALESCE(SUM(pi.Quantity * pi.UnitPrice), 0))
                          AS Revenue
               FROM Product p
               LEFT JOIN PurchaseItem pi ON p.ProductID = pi.ProductID
               LEFT JOIN Purchase pu ON pi.PurchaseID = pu.PurchaseID
                    AND pu.Status <> 'Cancelled'
               GROUP BY p.ProductID, p.Name
               ORDER BY COALESCE(SUM(pi.Quantity * pi.UnitPrice), 0) DESC"""
        ).fetchall()
    print_rows(rows)


def main() -> None:
    initialize_database()
    menu = {
        "1": ("View active products", view_products),
        "2": ("Search products", search_products),
        "3": ("Add a product", add_product),
        "4": ("Restock a product", restock_product),
        "5": ("Create a purchase", create_purchase),
        "6": ("View customer purchase history", purchase_history),
        "7": ("View sales report", sales_report),
    }
    while True:
        print("\nE-Commerce Database Menu")
        for key, (label, _) in menu.items():
            print(f"{key}. {label}")
        print("8. Reset database to sample data")
        print("0. Exit")
        choice = input("Choose an option: ").strip()
        if choice == "0":
            print("Goodbye.")
            break
        if choice == "8":
            initialize_database(reset=True)
            continue
        action = menu.get(choice)
        if action:
            try:
                action[1]()
            except sqlite3.Error as exc:
                print(f"Database error: {exc}")
        else:
            print("Choose a valid menu option.")


if __name__ == "__main__":
    main()
