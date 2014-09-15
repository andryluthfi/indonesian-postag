select 

	lemma_name as lemma,
	lexical_abbreviation as tag
 
from lemma 
	left join lemma_type on lemma_type.lemma_id = lemma.lemma_id
	left join definition on definition.definition_lemma_id = lemma.lemma_id 	
	left join lexical on lexical.lexical_id = definition.definition_lexical_id
where 
lemma.lemma_name like '% %' and
type_id = 3 
/*and lexical_abbreviation is not null*/