"""Render ingress port regressions with Helm; no cluster or Python packages needed."""
import os
from pathlib import Path
import re
import subprocess
import unittest

CHART = Path(__file__).resolve().parents[1] / "charts" / "portainer"


class IngressPortsTest(unittest.TestCase):
    def test_backend_ports(self):
        for version in ("1.19.0", "1.20.0"):
            for tls in (False, True):
                for custom, override in ((False, None), (True, None), (True, 12345)):
                    with self.subTest(version=version, tls=tls, custom=custom, override=override):
                        http, https = (8080, 8443) if custom else (9000, 9443)
                        values = {
                            "ingress.enabled": "true",
                            "ingress.hosts[0].host": "portainer.example.com",
                            "ingress.hosts[0].paths[0].path": "/",
                            "tls.force": str(tls).lower(),
                            "service.httpPort": str(http),
                            "service.httpsPort": str(https),
                        }
                        if override is not None:
                            values["ingress.hosts[0].paths[0].port"] = str(override)
                        cmd = [os.environ.get("HELM", "helm"), "template", "portainer", str(CHART),
                               "--kube-version", version]
                        for key, value in values.items():
                            cmd += ["--set", f"{key}={value}"]
                        rendered = subprocess.check_output(cmd, text=True)
                        ingress = next(doc for doc in rendered.split("---") if "kind: Ingress\n" in doc)
                        backend = re.search(r"(?:number|servicePort): (\d+)", ingress)
                        expected = override if override is not None else (https if tls else http)
                        self.assertIsNotNone(backend)
                        self.assertEqual(int(backend.group(1)), expected)
                        if override is None:
                            service = next(doc for doc in rendered.split("---") if "kind: Service\n" in doc)
                            self.assertRegex(service, rf"- port: {expected}\n")


if __name__ == "__main__":
    unittest.main()
