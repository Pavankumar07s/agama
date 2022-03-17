import StorageClient from "./storage";

// NOTE: should we export them?
const STORAGE_PROPOSAL_IFACE = "org.opensuse.DInstaller.Storage.Proposal1";
const STORAGE_ACTIONS_IFACE = "org.opensuse.DInstaller.Storage.Actions1";

const dbusClient = {};
const storageProposalProxy = {
  wait: jest.fn(),
  AvailableDevices: [
    {
      t: "av",
      v: [
        { t: "s", v: "/dev/sda" },
        { t: "s", v: "/dev/sda, 950 GiB, Windows" },
        { t: "a{sv}", v: {} }
      ]
    },
    {
      t: "av",
      v: [
        { t: "s", v: "/dev/sdb" },
        { t: "s", v: "/dev/sdb, 500 GiB" },
        { t: "a{sv}", v: {} }
      ]
    }
  ],
  CandidateDevices: [{ t: "s", v: "/dev/sda" }],
  LVM: true
};

const storageActionsProxy = {
  wait: jest.fn(),
  All: [
    {
      t: "a{sv}",
      v: {
        Text: { t: "s", v: "Mount /dev/sdb1 as root" },
        Subvol: { t: "b", v: false },
        Delete: { t: "b", v: false }
      }
    }
  ]
};

const proxies = {
  [STORAGE_PROPOSAL_IFACE]: storageProposalProxy,
  [STORAGE_ACTIONS_IFACE]: storageActionsProxy
};

beforeEach(() => {
  dbusClient.proxy = jest.fn().mockImplementation(iface => {
    return proxies[iface];
  });
});

describe("#getStorageProposal", () => {
  it("returns the storage proposal settings", async () => {
    const client = new StorageClient(dbusClient);
    const proposal = await client.getStorageProposal();
    expect(proposal).toEqual({
      availableDevices: [
        { id: "/dev/sda", label: "/dev/sda, 950 GiB, Windows" },
        { id: "/dev/sdb", label: "/dev/sdb, 500 GiB" }
      ],
      candidateDevices: ["/dev/sda"],
      lvm: true
    });
  });
});

describe("#getStorageActions", () => {
  it("returns the storage actions", async () => {
    const client = new StorageClient(dbusClient);
    const actions = await client.getStorageActions();
    expect(actions).toEqual([{ text: "Mount /dev/sdb1 as root", subvol: false, delete: false }]);
  });
});