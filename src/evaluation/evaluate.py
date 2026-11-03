import json, math, statistics

def precision_at_k(retrieved, relevant, k):
    top = retrieved[:k]
    return sum(x in relevant for x in top) / max(k, 1)

def recall_at_k(retrieved, relevant, k):
    top = set(retrieved[:k])
    return len(top.intersection(relevant)) / max(len(relevant), 1)

def reciprocal_rank(retrieved, relevant):
    for i, item in enumerate(retrieved, 1):
        if item in relevant:
            return 1/i
    return 0.0

def evaluate_case(case):
    retrieved = case["retrieved_ids"]
    relevant = set(case["relevant_ids"])
    return {
        "precision@5": precision_at_k(retrieved, relevant, 5),
        "recall@5": recall_at_k(retrieved, relevant, 5),
        "mrr": reciprocal_rank(retrieved, relevant),
        "grounded": bool(case.get("grounded", False))
    }

if __name__ == "__main__":
    cases = json.load(open("evaluation/dataset.json"))
    scores = [evaluate_case(c) for c in cases]
    print(json.dumps(scores, indent=2))
