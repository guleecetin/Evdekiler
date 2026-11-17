import { api } from "./api";

export type Role = "User" | "Admin";

export type AdminUser = {
  id: string;
  email: string;
  displayName: string;
  role: Role;
  createdAt: string;
};

export type UserPage = {
  items: AdminUser[];
  page: number;
  pageSize: number;
  totalCount: number;
  adminCount: number;
};

export function listUsers(page: number, pageSize: number, search: string, role: Role | null) {
  const query = new URLSearchParams({ page: String(page), pageSize: String(pageSize) });
  if (search) query.set("search", search);
  if (role) query.set("role", role);
  return api<UserPage>(`/api/users?${query}`);
}

export function changeRole(id: string, role: Role) {
  return api<AdminUser>(`/api/users/${id}/role`, { method: "PUT", body: { role } });
}