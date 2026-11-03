from src.query.handler import _access_filter


def test_access_filter_uses_both_verified_claim_dimensions():
    assert _access_filter("cardiology", "clinician") == {
        "andAll": [
            {"equals": {"key": "department", "value": "cardiology"}},
            {"listContains": {"key": "access_roles", "value": "clinician"}},
        ]
    }
