/// Cleans up orphaned fire after a room change or removal of its owner.
if (!instance_exists(self.owner)) instance_destroy()
