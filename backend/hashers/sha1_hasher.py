"""Legacy SHA1 password hasher for compatibility."""

import hashlib
from typing import Any, Dict, Optional

from django.contrib.auth.hashers import BasePasswordHasher, mask_hash
from django.utils.crypto import constant_time_compare
from django.utils.translation import gettext_noop as _


class LegacySHA1PasswordHasher(BasePasswordHasher):
    """Password hasher compatible with legacy SHA1 encoded passwords."""

    # Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/>

    algorithm = "sha1"

    def encode(self, password: str, salt: str, iterations: Optional[int] = None) -> str:
        """Return the encoded hash, matching the legacy SHA1 format."""
        assert password is not None
        if salt is None:
            raise ValueError("Salt must not be None.")
        if "$" in salt:
            raise ValueError("Salt cannot contain the '$' character.")

        hash_ = hashlib.sha1((salt + password).encode("utf-8")).hexdigest()
        return f"{self.algorithm}${salt}${hash_}"

    def verify(self, password: str, encoded: str) -> bool:
        """Check whether the provided password matches the encoded hash."""
        try:
            algorithm, salt, _ = encoded.split("$", 2)
        except ValueError:
            return False
        if algorithm != self.algorithm:
            return False
        encoded_2 = self.encode(password, salt)
        return constant_time_compare(encoded, encoded_2)

    def must_update(self, encoded: str) -> bool:
        """Mark hashes for upgrade to the project's default algorithm."""
        return True

    def safe_summary(self, encoded: str) -> Dict[str, Any]:
        """Provide a human readable summary of the hash contents."""
        algorithm, salt, hash_ = encoded.split("$", 2)
        return {
            _("algorithm"): algorithm,
            _("salt"): mask_hash(salt),
            _("hash"): mask_hash(hash_),
        }
