# example from chatgpt
from habanero import Crossref
import json

def fetch_paper_data(doi):
    cr = Crossref()
    try:
        paper_data = cr.works(ids=doi)
        return paper_data
    except Exception as e:
        print(f"Error fetching DOI {doi}: {e}")
        return None

def extract_citations(paper_data):
    citations = []
    if paper_data and 'reference' in paper_data['message']:
        for ref in paper_data['message']['reference']:
            citation = {
                "DOI": ref.get("DOI", "N/A"),
                "Title": ref.get("article-title", "N/A"),
                "Author": ref.get("author", "N/A"),
            }
            citations.append(citation)
    return citations

def main():
    doi = input("Enter the DOI of the paper: ").strip()
    paper_data = fetch_paper_data(doi)
    if paper_data:
        print("\nPaper Metadata:")
        print(json.dumps(paper_data['message'], indent=4))
        
        citations = extract_citations(paper_data)
        print("\nCited Papers:")
        if citations:
            print(json.dumps(citations, indent=4))
        else:
            print("No citation data available.")
    else:
        print("No data found for the given DOI.")

if __name__ == "__main__":
    main()
