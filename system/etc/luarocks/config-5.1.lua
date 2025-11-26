-- LuaRocks configuration

rocks_trees = {
   { name = "user", root = home .. "/.luarocks" };
   { name = "system", root = "/usr" };
}
variables = {
   LUA_DIR = "/usr";
   LUA_INCDIR = "/usr/include/lua5.1";
   LUA_BINDIR = "/usr/bin";
   LUA_LIBDIR = "/usr/lib64/lua/5.1";
   LUA_VERSION = "5.1";
   LUA = "/usr/bin/lua5.1";
}
