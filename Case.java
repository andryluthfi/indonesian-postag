import java.util.List;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.AbstractMap;

public class Case {

	public List<Map.Entry<Integer,Premises.Premise>> ambigousIndeces;
	public List<String> tokens;
	private int current;
	private boolean isTrace;

	public Case(String[] ambigousIndecesNumber, boolean isTrace) {
		this.resetCurrent();
		this.ambigousIndeces = new ArrayList<Map.Entry<Integer,Premises.Premise>>();
		for(String indexNumber : ambigousIndecesNumber) {
			Map.Entry<Integer,Premises.Premise> index = new AbstractMap.SimpleEntry<Integer,Premises.Premise>(Integer.parseInt(indexNumber) - 1, null);
			this.ambigousIndeces.add(index);
		}
		this.isTrace = isTrace;
		this.tokens = new ArrayList<String>();
	}

	public Case(String[] ambigousIndecesNumber) {
		this(ambigousIndecesNumber, false);
	}

	public void resetCurrent() {
		this.current = 0;
	}

	public void addToken(String line) {
		String newTagsLine = "";
		String[] columns = line.split("\t");
		Map<String,Boolean> map = new HashMap<String, Boolean>();
		if(columns.length >= 2) {
			String[] tags = columns[1].split(",");
			for(String tag : tags) {
				if(!map.containsKey(tag)) {
					map.put(tag, true);				
				}
			}
			boolean isFirst = true;
			for(String tag : map.keySet()) {
				newTagsLine += (isFirst ? "" : ",") + tag;
				isFirst = false;
			}
		}
		this.tokens.add(columns[0] + "\t" + newTagsLine);
	}


	public boolean hasNextAmbigous() {
		boolean hasNextAmbigous = this.current < this.ambigousIndeces.size();
		// System.out.println(this.current + " < " + this.ambigousIndeces.size());
		if(hasNextAmbigous) {
			hasNextAmbigous &= this.ambigousIndeces.get(this.current).getValue() == null;
			// System.out.println(" -current : " + this.current);
			if(!hasNextAmbigous) {
				this.nextAmbigous();
				hasNextAmbigous |= this.hasNextAmbigous();
			}
		}
		return  hasNextAmbigous;
	}

	public void nextAmbigous() {
		this.current++;
	}

	public int getCurrentIndex() {
		return this.ambigousIndeces.get(this.current).getKey();
	}

	public String getCurrentToken() {
		return this.tokens.get(this.getCurrentIndex());
	}

	public int getTotalUnresolved() {
		int total = 0;
		for(Map.Entry<Integer,Premises.Premise> ambigousIndex : this.ambigousIndeces) {
			boolean isSolved = ambigousIndex.getValue() != null;
			if(!isSolved) {
				total++;
			}
		}
		return total;
	}

	public Premises.Premise getCurrentFoundedPremise() {
		return this.ambigousIndeces.get(this.current).getValue();
	}

	public void setCurrentToken(String newToken) {
		int current = this.getCurrentIndex();
		this.tokens.set(current, newToken);
	}

	public void founded(Premises.Premise foundedPremise) {
		Map.Entry<Integer,Premises.Premise> ambigousIndex = this.ambigousIndeces.get(this.current);
		ambigousIndex.setValue(foundedPremise);
	}

	public String solutionOutputs(String solvedTag) {
		String output = "";
		for(int i=0; i<this.tokens.size(); i++) {
			String token = this.tokens.get(i);
			if(i == this.getCurrentIndex()) {
				String[] tokenParts = token.split("\t");
				token = String.format("%s\t%s",tokenParts[0], this.isTrace ? String.format("%s\t%s\t%s", solvedTag, tokenParts[1], "debug-00") : solvedTag); 
			}
			output += String.format("%s\n",token);
		}
		return output;
	}

	public String solutionOutput(String solvedTag) {
		String token = this.getCurrentToken();
		String[] tokenParts = token.split("\t");
		Premises.Premise foundedPremise = this.getCurrentFoundedPremise();
		return String.format("%s\t%s",tokenParts[0], 
			this.isTrace ? (
				( foundedPremise != null) ?  
					String.format("%s\t%s\t%s", solvedTag, tokenParts[1], foundedPremise.parent.getID()) : 
					String.format("%s\t%s\tno rule matched", solvedTag, solvedTag)
				) :
				String.format("%s", solvedTag)
		);
	}

	@Override
	public String toString() {
		String string = "";
		for(Map.Entry<Integer,Premises.Premise> ambigousIndex : this.ambigousIndeces) {
			string += String.format("%s \n", this.tokens.get(ambigousIndex.getKey()));
		}
		return string;
	}
}
