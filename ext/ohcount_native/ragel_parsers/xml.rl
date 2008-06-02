// xml.rl written by Mitchell Foral. mitchell<att>caladbolg<dott>net.

/************************* Required for every parser *************************/
#ifndef RAGEL_XML_PARSER
#define RAGEL_XML_PARSER

#include "ragel_parser_macros.h"

// the name of the language
const char *XML_LANG = "xml";

// the languages entities
const char *xml_entities[] = {
  "space", "comment", "doctype",
  "tag", "entity", "any"
};

// constants associated with the entities
enum {
  XML_SPACE = 0, XML_COMMENT, XML_DOCTYPE,
  XML_TAG, XML_ENTITY, XML_ANY
};

/*****************************************************************************/

%%{
  machine xml;
  write data;
  include common "common.rl";

  # Line counting machine

  action xml_ccallback {
    switch(entity) {
    case XML_SPACE:
      ls
      break;
    case XML_ANY:
      code
      break;
    case INTERNAL_NL:
      std_internal_newline(XML_LANG)
      break;
    case NEWLINE:
      std_newline(XML_LANG)
      break;
    case CHECK_BLANK_ENTRY:
      check_blank_entry(XML_LANG)
    }
  }

  xml_comment =
    '<!--' @comment (
      newline %{ entity = INTERNAL_NL; } %xml_ccallback
      |
      ws
      |
      (nonnewline - ws) @comment
    )* :>> '-->';

  xml_sq_str =
    '\'' @code (
      newline %{ entity = INTERNAL_NL; } %xml_ccallback
      |
      ws
      |
      [^\r\n\f\t '\\] @code
      |
      '\\' nonnewline @code
    )* '\'';
  xml_dq_str =
    '"' @code (
      newline %{ entity = INTERNAL_NL; } %xml_ccallback
      |
      ws
      |
      [^\r\n\f\t "\\] @code
      |
      '\\' nonnewline @code
    )* '"';
  xml_cdata_str =
    '<![CDATA[' @code (
      newline %{ entity = INTERNAL_NL; } %xml_ccallback
      |
      ws
      |
      (nonnewline - ws) @code
    )* :>> ']]>';
  xml_string = xml_sq_str | xml_dq_str | xml_cdata_str;

  xml_line := |*
    spaces       ${ entity = XML_SPACE; } => xml_ccallback;
    xml_comment;
    xml_string;
    newline      ${ entity = NEWLINE;   } => xml_ccallback;
    ^space       ${ entity = XML_ANY;   } => xml_ccallback;
  *|;

  # Entity machine

  action xml_ecallback {
    callback(XML_LANG, entity, cint(ts), cint(te));
  }

  xml_entity := 'TODO:';
}%%

/************************* Required for every parser *************************/

/* Parses a string buffer with XML markup.
 *
 * @param *buffer The string to parse.
 * @param length The length of the string to parse.
 * @param count Integer flag specifying whether or not to count lines. If yes,
 *   uses the Ragel machine optimized for counting. Otherwise uses the Ragel
 *   machine optimized for returning entity positions.
 * @param *callback Callback function. If count is set, callback is called for
 *   every line of code, comment, or blank with 'lcode', 'lcomment', and
 *   'lblank' respectively. Otherwise callback is called for each entity found.
 */
void parse_xml(char *buffer, int length, int count,
  void (*callback) (const char *lang, const char *entity, int start, int end)
  ) {
  init

  %% write init;
  cs = (count) ? xml_en_xml_line : xml_en_xml_entity;
  %% write exec;

  // if no newline at EOF; callback contents of last line
  if (count) { process_last_line(XML_LANG) }
}

#endif

/*****************************************************************************/