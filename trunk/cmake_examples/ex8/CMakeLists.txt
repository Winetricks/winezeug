# Given two rules,
# one that builds a file but puts it into directory X,
# and another that consumes that file but expects it in directory Y,
# how do you write a rule to copy the file from directory X to directory Y
# after the file is built but before it is consumed?

# The two rules you're trying to glue together
add_custom_command(
	OUTPUT a/foo.dat
	COMMAND ${CMAKE_COMMAND} -E make_directory a
	COMMAND ${CMAKE_COMMAND} -E touch a/foo.dat
)
add_custom_target(blah ALL 
	DEPENDS b/foo.dat
	COMMAND cat b/foo.dat
)

# The glue to tie them together
add_custom_command(
	OUTPUT b/foo.dat
	DEPENDS a/foo.dat
	COMMAND ${CMAKE_COMMAND} -E make_directory b
	COMMAND ${CMAKE_COMMAND} -E copy a/foo.dat b/foo.dat
)

# Not sure how to add rules to 'clean', so create a 'klean' alongside it
add_custom_target(klean)
add_custom_command(
	TARGET klean
	COMMAND ${CMAKE_COMMAND} -E remove_directory a
	COMMAND ${CMAKE_COMMAND} -E remove_directory b
)
