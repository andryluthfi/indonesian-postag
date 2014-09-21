
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class MorphAnalysis {

	private static boolean isFiltered = true;
	private static boolean isVerbose = false;
	
	public static void main(String[] arguments) {
		String fileName = "res-preMorphAnalysis.txt";
		String outputName = "res-morphAnalysis.txt";
		for(String argument : arguments) {
			if(argument.contains("-f=")) {
				fileName = argument.split("=")[1];
			}
			else if(argument.contains("-o=")) {
				outputName = argument.split("=")[1];
			}
			else if(argument.equalsIgnoreCase("-verbose")) {
				isVerbose = true;
			}
			else if(argument.equalsIgnoreCase("-unfilter")) {
				isFiltered = false;
			}

		}
		if(isVerbose) {
			System.out.println("Memulai MorphInd ....");
		}
		Process process;
		Pattern pattern = Pattern.compile("_(?<tag>[\\w\\-]{3})");
		try {
			String line;
			StringBuilder lineBuilder = new StringBuilder();
			BufferedReader readerContent = new BufferedReader(new FileReader(fileName)); 
			BufferedWriter  writer = new BufferedWriter (new FileWriter(outputName));
			boolean isFirst = true;
			while ((line = readerContent.readLine()) != null) {
				String[] columns = line.split("\t");
				lineBuilder = new StringBuilder();
				Matcher matcher = pattern.matcher(line);
				isFirst = true;
				Map<String, Boolean> checker = new HashMap<String, Boolean>();
				while(matcher.find()) {
					String tag = mapPOSTag(matcher.group("tag"));
					if(!tag.equals("") && !checker.containsKey(tag)) {
						lineBuilder.append((isFirst ? "" : ",") + tag);
						checker.put(tag, true);
						isFirst = false;
					}
				}
				writer.write(columns[0] + "\t" + lineBuilder.toString());
				writer.newLine();
			}	

			writer.flush();
			writer.close();

		} catch (Exception e) {
			e.printStackTrace();
		}
		
	}

	public static String mapPOSTags(Map<String, Integer> posTags) {
		String outputs = "";
		boolean isFirst = true;
		for(String posTag : posTags.keySet()) {
			String tag = MorphAnalysis.mapPOSTag(posTag);
			if(!tag.equals("")){
				outputs += (isFirst ? "" : ",") + tag;
				isFirst = false;
			}
		}
		return outputs;
	}

	public static String mapPOSTag(String posTag) {
		String code = "";
		String singleCode = posTag.substring(0,1);
		String dualCode = posTag.substring(0,2);
		if(singleCode.equalsIgnoreCase("A")) {
			code = "JJ";
		} else if(singleCode.equalsIgnoreCase("B")) {
			code = "DT,PR";
		} else if(dualCode.equalsIgnoreCase("CD") || dualCode.equalsIgnoreCase("CC")) {
			code = "CD";
		} else if(dualCode.equalsIgnoreCase("CO")) {
			code = "OD";
		} else if(singleCode.equalsIgnoreCase("D")) {
			code = "RB";
		} else if(singleCode.equalsIgnoreCase("F")) {
			code = "FW";
		} else if(singleCode.equalsIgnoreCase("G")) {
			code = "NEG";
		} else if(singleCode.equalsIgnoreCase("H")) {
			code = "CC";
		} else if(singleCode.equalsIgnoreCase("I")) {
			code = "UH";
		} else if(singleCode.equalsIgnoreCase("M")) {
			code = "MD";
		} else if(dualCode.equalsIgnoreCase("NP")) {
			code = "NN";
		} else if(posTag.equalsIgnoreCase("NSF") || posTag.equalsIgnoreCase("NSM")) {
			code = "NN";
		} else if(posTag.equalsIgnoreCase("NSD")) {
			// Noun-singular-non-specified (NN: warisan; NND: ton;
			// NNP: Indonesia; SYM: Rp)**
			code = "NN";
		} else if(singleCode.equalsIgnoreCase("O")) {
			code = "VB";
		} else if(singleCode.equalsIgnoreCase("P")) {
			code = "PRP";
		} else if(singleCode.equalsIgnoreCase("R")) {
			code = "IN";
		} else if(singleCode.equalsIgnoreCase("S")) {
			code = "SC";
		} else if(singleCode.equalsIgnoreCase("T")) {
			code = "RP";
		} else if(singleCode.equalsIgnoreCase("V")) {
			code = "VB";
		} else if(singleCode.equalsIgnoreCase("W")) {
			code = "WH";
		} else if(singleCode.equalsIgnoreCase("X")) {
			code = "X";
		} else if(singleCode.equalsIgnoreCase("Y")) {
			code = "Z,SYM";
		} 


		return isFiltered ? ( ((code.equals("VB") || code.equals("NN") || code.equals("JJ"))) ? code : "") : code;
	}		
}
