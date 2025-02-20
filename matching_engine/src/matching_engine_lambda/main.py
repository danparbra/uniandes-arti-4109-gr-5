import threading
import time


class OrderMatchingSystemMock:
    def __init__(self, interval=0.1):
        self.interval = interval  # Intervalo en segundos
        self.ordenes = [  # Mock de la BD con órdenes de compra y venta
            {"id": 1, "tipo": "venta", "activo_id": "AAPL", "precio": 150},
            {"id": 2, "tipo": "compra", "activo_id": "AAPL", "precio": 150},
            {"id": 3, "tipo": "venta", "activo_id": "TSLA", "precio": 600},
            {"id": 4, "tipo": "compra", "activo_id": "TSLA", "precio": 500},
        ]
        self.matches = []  # Lista para guardar los emparejamientos

    def ConsultarOrdenesdeVenta(self, identificador_activo):
        """Devuelve órdenes de venta filtradas por activo."""
        return [
            o
            for o in self.ordenes
            if o["tipo"] == "venta" and o["activo_id"] == identificador_activo
        ]

    def ConsultarOrdenesdeCompra(self, identificador_activo):
        """Devuelve órdenes de compra filtradas por activo."""
        return [
            o
            for o in self.ordenes
            if o["tipo"] == "compra" and o["activo_id"] == identificador_activo
        ]

    def Emparejamiento(self):
        """Empareja órdenes de compra y venta según las reglas de activo y precio."""
        activos = {o["activo_id"] for o in self.ordenes}  # Obtener activos únicos
        for activo_id in activos:
            ventas = self.ConsultarOrdenesdeVenta(activo_id)
            compras = self.ConsultarOrdenesdeCompra(activo_id)

            for compra in compras:
                for venta in ventas:
                    if self.evaluar_regla_de_activo(compra, venta):
                        self.registrar_match(compra, venta)

    def evaluar_regla_de_activo(self, compra, venta):
        """Regla: la orden de compra debe coincidir con la de venta en activo y precio."""
        return (
            compra["precio"] == venta["precio"]
            and compra["activo_id"] == venta["activo_id"]
        )

    def registrar_match(self, compra, venta):
        """Guarda el match en la lista en memoria."""
        match = {
            "compra_id": compra["id"],
            "venta_id": venta["id"],
            "activo_id": compra["activo_id"],
            "precio": compra["precio"],
        }
        self.matches.append(match)
        print(
            f"Match registrado: Compra {compra['id']} con Venta {venta['id']} para {compra['activo_id']} a {compra['precio']}"
        )

    def start_matcher(self):
        """Inicia el emparejamiento en un hilo separado."""

        def run():
            while True:
                print("Ejecutando emparejamiento...")
                self.Emparejamiento()
                time.sleep(self.interval)

        thread = threading.Thread(target=run, daemon=True)
        thread.start()


def handler(event, context):
    print("Iniciando emparejamiento de órdenes...")
    matcher = OrderMatchingSystemMock()
    matcher.start_matcher()
    print("Emparejamiento de órdenes finalizado.")
    return {"statusCode": 200, "body": "Emparejamiento de órdenes finalizado."}
