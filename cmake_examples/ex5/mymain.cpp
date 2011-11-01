#include <gtest/gtest.h>

TEST(DemoTest, HelloGtest)
{
   static int a[3] = {1, 2, 3};
   static int b[3] = {3, 2, 1};
   EXPECT_EQ(a[1], b[1]) << " center row should be constant";
}
