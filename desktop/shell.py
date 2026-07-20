#!/usr/bin/env python3
"""RebuiltTux 2 desktop shell prototype."""

import tkinter as tk

root = tk.Tk()
root.title("RebuiltTux Desktop")
root.geometry("1000x600")

tk.Label(root, text="RebuiltTux 2", font=("Arial", 32)).pack(pady=50)
tk.Label(root, text="Desktop session running").pack()

root.mainloop()
