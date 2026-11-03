from src.evaluation.evaluate import precision_at_k, recall_at_k, reciprocal_rank
def test_metrics():
    r=["a","b","c"]; rel={"b"}
    assert precision_at_k(r,rel,3)==1/3
    assert recall_at_k(r,rel,3)==1
    assert reciprocal_rank(r,rel)==0.5
