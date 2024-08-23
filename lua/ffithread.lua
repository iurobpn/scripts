local M = {}
M.ffi = require('ffi')

M.ffi.cdef[[

typedef unsigned long int pthread_t;

typedef union 
{
  char size[56];
  long int align;
} pthread_attr_t ;
extern int pthread_create(pthread_t *newthread,
			   const pthread_attr_t *attr,
			   void *(*start_routine) (void *),
			   void *arg);

/* Terminate calling thread.

   The registered cleanup handlers are called via exception handling
   so we cannot mark this function with __THROW.*/
void pthread_exit(void *retval);

/* Make calling thread wait for termination of the thread TH.  The
   exit status of the thread is stored in *THREAD_RETURN, if THREAD_RETURN
   is not NULL.

   This function is a cancellation point and therefore not marked with
   __THROW.  */
int pthread_join(pthread_t th, void **thread_return);
]]

-- local pipe = M.uv.new_pipe(false)
-- pipe:read_start(function(err, data)
--   if err then
--     print('Error reading from pipe:', err)
--     return
--   end
--   print('Received data: ', data)
-- end)

M.Thread = {
    alive = false,
    func = nil,
    thread = M.ffi.new("pthread_t[1]")
    -- pipe = pipe
}
require('class').class(M.Thread, function(obj,func)
    obj.func = func
    return obj
end)
-- function M.Thread.__call(func)
--     local self = setmetatable({func = func, {__index = M.Thread})
--     return self
-- end

function M.Thread.start(self, ...)
    if self.thread and self.alive then
        print("Thread is already running.")
        return
    end
    self.alive = true
    -- self.thread = M.uv.new_thread(self.func, ...)
    M.ffi.C.pthread_create(self.thread, nil, self.func, nil)
    -- print("Thread started.")
end

function M.Thread.join(self)
    if not self.thread or not self.alive then
        print("No active thread to join.")
        return
    end
    -- Wait for the thread to finish
    M.ffi.C.pthread_join(self.thread[0], nil)
    self.alive = false
    -- print("Thread joined.")
end

return M
