#!/usr/bin/env python3
"""RebuiltTux 2 graphical installer prototype."""

import tkinter as tk

root = tk.Tk()
root.title("Install RebuiltTux 2")
root.geometry("800x500")

tk.Label(root, text="RebuiltTux 2 Installer", font=("Arial", 28)).pack(pady=50)
tk.Label(root, text="Installation wizard coming soon").pack()

root.mainloop()
