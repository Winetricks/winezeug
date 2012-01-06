# Same as ex8, but with targets instead of output files

# Given two rules,
# one that builds a file but puts it into directory X,
# and another that consumes that file but expects it in directory Y,
# how do you write a rule to copy the file from directory X to directory Y
# after the file is built but before it is consumed?

# The two rules you're trying to glue together

# Generate the file
add_custom_target(target_a)
add_custom_command(
	TARGET target_a
	COMMAND ${CMAKE_COMMAND} -E make_directory a
	COMMAND ${CMAKE_COMMAND} -E touch a/foo.dat
)

# Consume it
add_custom_target(sink ALL
	DEPENDS target_b
)
add_custom_command(
	TARGET sink
	COMMAND cat b/foo.dat
)

# The glue to tie them together
add_custom_target(target_b
	DEPENDS target_a
)
add_custom_command(
	TARGET target_b
	COMMAND ${CMAKE_COMMAND} -E make_directory b
	COMMAND ${CMAKE_COMMAND} -E copy a/foo.dat b/foo.dat
)
