
import os
import subprocess
import luigi
import snowflake.connector
from dotenv import load_dotenv

# Charger les variables d'environnement depuis le .env à la racine
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

load_dotenv(os.path.join(PROJECT_ROOT, ".env"))

# Chemin du projet dbt
DBT_PROJECT_DIR = os.path.join(PROJECT_ROOT, "dbt", "nyc_taxi_dbt")


def run_dbt(command):
    """Exécute une commande dbt depuis le dossier du projet."""
    subprocess.run(
        ["dbt"] + command,
        cwd=DBT_PROJECT_DIR,
        check=True
    )


class CheckRawData(luigi.Task):
    """Vérifie que les données RAW sont disponibles."""

    def output(self):
        return luigi.LocalTarget("logs/raw_check.done")

    def run(self):
        connection = snowflake.connector.connect(
            account=os.getenv("SNOWFLAKE_ACCOUNT"),
            user=os.getenv("SNOWFLAKE_USER"),
            password=os.getenv("SNOWFLAKE_PASSWORD"),
            warehouse="NYC_TAXI_WH",
            database="NYC_TAXI",
            schema="RAW",
            role="ACCOUNTADMIN",
        )

        try:
            cursor = connection.cursor()
            cursor.execute(
                "SELECT COUNT(*) FROM NYC_TAXI.RAW.YELLOW_TRIPS"
            )
            row_count = cursor.fetchone()[0]

            if row_count == 0:
                raise ValueError("La table RAW.YELLOW_TRIPS est vide.")

            print(f"RAW.YELLOW_TRIPS contient {row_count:,} lignes.")

        finally:
            connection.close()

        os.makedirs("logs", exist_ok=True)

        with self.output().open("w") as file:
            file.write(f"RAW vérifié : {row_count} lignes")


class RunStaging(luigi.Task):
    """Exécute les modèles dbt STAGING."""

    def requires(self):
        return CheckRawData()

    def output(self):
        return luigi.LocalTarget("logs/staging.done")

    def run(self):
        run_dbt(["run", "--select", "staging"])

        os.makedirs("logs", exist_ok=True)

        with self.output().open("w") as file:
            file.write("STAGING terminé")


class RunMarts(luigi.Task):
    """Exécute les modèles dbt MARTS."""

    def requires(self):
        return RunStaging()

    def output(self):
        return luigi.LocalTarget("logs/marts.done")

    def run(self):
        run_dbt(["run", "--select", "marts"])

        os.makedirs("logs", exist_ok=True)

        with self.output().open("w") as file:
            file.write("MARTS terminé")


class RunTests(luigi.Task):
    """Exécute les tests dbt après les modèles."""

    def requires(self):
        return RunMarts()

    def output(self):
        return luigi.LocalTarget("logs/tests.done")

    def run(self):
        run_dbt(["test"])

        os.makedirs("logs", exist_ok=True)

        with self.output().open("w") as file:
            file.write("Tests dbt réussis")


if __name__ == "__main__":
    luigi.run(
        main_task_cls=RunTests,
        local_scheduler=True
    )
