/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.AbstractMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 *
 * @author Andry Luthfi
 */
public class Rules {

    private List<List<Map.Entry<String, Premises>>> list;

    public Rules() {
        this.list = new ArrayList<List<Map.Entry<String, Premises>>>();
    }

    public void addRule(String[] tags, Premises premises) {
        List<Map.Entry<String, Premises>> listTag = new ArrayList<Map.Entry<String, Premises>>();
        for (String tag : tags) {
            listTag.add(new AbstractMap.SimpleEntry<String, Premises>(tag, premises));
        }
        this.list.add(listTag);
    }

    public String trace(Case ambigousCase) {
        List<String> subContext = ambigousCase.tokens;
        String output = "";
        String ambigousElement = ambigousCase.getCurrentToken();

        String[] ambigousElements = ambigousElement.split("\t");
        String ambigousWord = ambigousElements[0];
        String[] ambigousTags =  ambigousElements[1].split(",");
        boolean isDone = false;
        for (List<Map.Entry<String, Premises>> tags : this.list) {
            if (this.isCompatible(ambigousTags, tags)) {
                Premises premises = (Premises) tags.get(0).getValue();
                for (Premises.Premise premise : premises.getList()) {
                    output = premise.trace(ambigousCase);
                    if(!("".equals(output))) {
                        ambigousCase.founded(premise);
                        isDone = true;
                        break;
                    }

                    if(!isDone && premise.grammar.equals("--")) {
                        	ambigousCase.founded(premise);
                        	output = premise.output;
                            isDone = true;
                            break;
                    }    
                }
            }

            if (isDone) {
                break;
            }
        }
		
		String word = ambigousCase.getCurrentToken().split("\t")[0];
        return isDone ? output : ambigousElements[1]; 
    }

    private boolean isCompatible(String[] ambigousTags, List<Map.Entry<String, Premises>> tags) {
        boolean isCompatible = ambigousTags.length == tags.size();
        if (isCompatible) {
	       	for (String ambigousTag : ambigousTags) {
				boolean isFound = false;
				for(Map.Entry<String, Premises> entry : tags) {
					if(entry.getKey().equals(ambigousTag)) {
						isFound = true;
						break;
					}
				}
				isCompatible &= isFound;
		       }
        }

        return isCompatible;
    }

    @Override
    public String toString() {
        String output = "";
        int i = 1;
        for (List<Map.Entry<String, Premises>> mapTags : this.list) {
            output += String.format("Rule #%2d : \n", i);
            for (Map.Entry<String, Premises> tag : mapTags) {
                output += String.format("[%s]: \n", tag.getKey());
                output += tag.getValue().toString();
            }
            i++;
        }
        return output;
    }
}
